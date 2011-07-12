package MT::Test::Base;

use strict;
use warnings;
use lib $ENV{MT_HOME} ? ("$ENV{MT_HOME}/lib", "$ENV{MT_HOME}/extlib")
                      : ("./lib", "./extlib");
use lib qw( addons/Log4MT.plugin/lib addons/Log4MT.plugin/extlib );

use base qw( Class::Accessor::Fast Class::Data::Inheritable );

use Carp qw( croak );
use Data::Dumper;
use Scalar::Util qw( blessed );
use List::Util qw( first );
use File::Spec;
use MT::Util qw( caturl );

__PACKAGE__->mk_accessors(qw(   blog  user  users
                                session_id  session_username  ));

# __PACKAGE__->mk_classdata(  );

BEGIN {
    # if MT_HOME is not set, set it
    unless ( $ENV{MT_HOME} ) {
        require Cwd;
        my $cwd    = Cwd::getcwd();
        my @pieces = File::Spec->splitdir($cwd);
        pop @pieces unless -e 'config.cgi' or -e 'mt-config.cgi';
        $ENV{MT_HOME} = File::Spec->catdir(@pieces);
    }

    # if MT_CONFIG is not set, set it
    if ( $ENV{MT_CONFIG} ) {
        if ( !File::Spec->file_name_is_absolute( $ENV{MT_CONFIG} ) ) {
            $ENV{MT_CONFIG}
              = File::Spec->catfile( $ENV{MT_HOME}, $ENV{MT_CONFIG} );
        }
    }
    else {
        use FindBin qw($Bin);
        my @dirs = ("$Bin/test.cfg", 
                    qw( t/sqlite-test.cfg config.cgi mt-config.cgi ));
        $ENV{MT_CONFIG}
            = first { -e $_ }
              map { File::Spec->file_name_is_absolute( $_ )
                        ? $_ : File::Spec->catfile( $ENV{MT_HOME}, $_ )
                } @dirs;
    }
    chdir $ENV{MT_HOME};

} ## end BEGIN

sub init {
    my $self = shift;
    $self->init_app( $ENV{MT_CONFIG} );
    $self->override_core_methods();
}

sub init_app {
    my $self = shift;
    my ($cfg) = @_;

    my $app = $ENV{MT_APP} || 'MT::App';
    eval "require $app; 1;" or die "Can't load $app: $@";

    $app->instance( $cfg ? ( Config => $cfg ) : () );
    require MT;

# print 'init_app: '.Dumper(MT->instance);
    # kill __test_output for a new request
    MT->add_callback(
        "${app}::init_request",
        1, undef,
        sub {
            $_[1]->{__test_output}    = '';
            $_[1]->{upgrade_required} = 0;
        }
    ) or die( MT->errstr );
} ## end sub init_app

sub test_basename {
    my $self = shift;
    (split("::", ( ref $self || $self )))[1];
}

sub init_test_blog {
    my $self    = shift;
    my $app     = MT->instance;
    my $basename = $self->test_basename();

    require MT::Util;

    my $blog = MT->model('blog')->get_by_key({
        name => $basename.' plugin test blog',
    });

    $app->config->DefaultSiteRoot
        or warn   "DefaultSiteRoot undefined in mt-config.cgi. "
                . "Test blog site path may be incorrect/invalid.";
    $blog->site_path(
        File::Spec->catdir( $app->config->DefaultSiteRoot, $basename ).'/'
    );

    $app->config->DefaultSiteURL
        or warn   "DefaultSiteURL undefined in mt-config.cgi. "
                . "Test blog site URL may be incorrect/invalid.";
    $blog->site_url(
        caturl( $app->config->DefaultSiteURL, $basename ).'/'
    );

    $blog->save();
    $self->blog( $blog );
}

sub init_test_user {
    my $self       = shift;
    my $basename   = $self->test_basename();
    my $user_class = MT->model('author');
    my $user       = $user_class->get_by_key({
        name      => $basename."_test",
        nickname  => $basename." plugin test user",
        auth_type => 'MT',
        password  => '',
    })
        or die "Could not create or load test user: ".$user_class->errstr;

    $user->save
        or die "Could not save test user: ".$user->errstr;

    my $role = MT->model('role')->load({ name => 'Author' });
    MT->model('association')->link( $user => $role => $self->blog );

    $self->users([ $user, @{$self->users||[]} ]);
    $self->user( $user );
}

sub init_data {
    my $self = shift;
    my $args = shift || {};
    $args = { yaml => $args } if $args and ! ref $args;

    my $extract_from_yaml = sub {
        my $y = shift || [];
        croak "Unexpected YAML object state: ".$y unless ref $y;
        shift @$y while @$y && ( ref( $y->[0] ) ne 'HASH' );
        return $y;
    };

    my $data = [];
    if ( $args->{yaml} ) {
        require YAML::Tiny;
        my $yaml = eval { YAML::Tiny->read_string( $args->{yaml} ) }
            or die join(' ',  "Error reading yaml string: ",
                              (YAML::Tiny->errstr||$@||$!), 
                              $args->{yaml},
                       );
        $data = $extract_from_yaml->($yaml);
    }
    elsif ( $args->{file} ) {
        my $file = $args->{file};
        require YAML::Tiny;
        my $yaml = eval { YAML::Tiny->read($file) }
            or die "Error reading $file: " . (YAML::Tiny->errstr||$@||$!);
        $data = $extract_from_yaml->($yaml);
    }
    elsif ( $args->{data} ) {
        $data = $args->{data};
    }

    foreach my $d ( @$data ) {
        foreach my $type ( keys %$d ) {
            my $props = $d->{$type};
            my $obj = MT->model($type)->get_by_key( $props )
                or die "Couldn't create $type object: ".MT->errstr;
            $obj->save()
                or die "Could not save $type object: ".$obj->errstr;
        }
    }
}

sub override_core_methods {
    my $self = shift;
    no warnings 'once';
    local $SIG{__WARN__} = sub { };

    *MT::App::print = sub {
        my $app = shift;
        $app->{__test_output} ||= '';
        $app->{__test_output} .= join( '', @_ );
    };

    my $orig_login = \&MT::App::login;
    *MT::App::login = sub {
        my $app = shift;
        if ( my $user = $app->query->param('__test_user') ) {

            # attempting to fake user session
            if (   !$self->session_id
                 || $user->name ne $self->session_username
                 || $app->query->param('__test_new_session') )
            {
                $app->start_session( $user, 1 );
                $self->session_id( $app->{session}->id );
                $self->session_username( $user->name );
            }
            else {
                $app->session_user( $user, $self->session_id );
            }
            $app->query->param( 'magic_token', $self->session_id );
            $app->user($user);
            return ( $user, 0 );
        }
        $orig_login->( $app, @_ );
    };
}

sub finish { }

1;