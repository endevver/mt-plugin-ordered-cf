package OrderedCF;

use strict;
use warnings;
use YAML;
use Data::Dumper;
use Carp qw( croak );
use List::Util qw( first );

use base qw( MT::Plugin Class::Data::Inheritable );

use Melody::Compat;  # Declare plugin requirement

__PACKAGE__->mk_classdata('Instance');

sub instance {
    my $pkg = shift;
    return $pkg->Instance if $pkg->Instance;

    # Try loading plugin using the buggy MT->component
    # See https://openmelody.lighthouseapp.com/projects/26604/tickets/990
    my ($instance)
        =  map { MT->component($_) } first { MT->component($_) }
               ( 'mt-plugin-ordered-cf', (ref $pkg||$pkg) );

    # If that didn't work, iterate over %MT::Components and check each 
    # component's 'id' registry value which should be OrderedCF for this 
    # plugin (as seen in config.yaml)
    ($instance)
        ||= map { MT->component($_) }
            first {
                eval {
                    MT->component($_)->registry('id') eq __PACKAGE__
                }
            } keys %MT::Components;
    return $pkg->Instance( $instance ) if $instance;
}

sub init_app {
    require OrderedCF::CustomFields::App::CMS;
    OrderedCF::CustomFields::App::CMS->override_methods( @_ );
}

sub init_request {
    my $app = shift;
    my $q = $app->query;
    return unless ref $app
              and $app->isa('MT::App::CMS')
              and $app->mode eq 'save'
              and $q->param('_type') eq 'blog';
    $q->delete('bar_position', 'custom_prefs');
}

sub post_init {
    my $cb     = shift;
    $cb->plugin->init_meta_fields(@_);
}

sub init_meta_fields {
    my $self = shift;
    my $perm_class = MT->model('permission');

    $perm_class->properties->{meta} = 1;
    $perm_class->install_meta({
        column_defs => $self->meta_field_column_defs()
    });

    eval "require ${perm_class}::Meta;";
    return 1;
}

sub load_prefs {
    my $self            = shift;
    my ($type, $args)   = @_;
    $args             ||= {};

    $type or croak "No object type specified for load_prefs";

    croak "Cannot load $type display prefs without blog_id or author_id "
         . Dumper(\@_)
         unless $args->{blog_id}
             or $args->{author_id}
             or $args->{type} eq 'author';

    require MT::Permission;
    my $perm = MT::Permission->load({
        blog_id   => $args->{blog_id}   || 0,
        author_id => $args->{author_id} || 0
    }) or return;

    my $loader = sub {
        my $col = shift;
        $perm->is_meta_column($col) ? $perm->meta($col, @_)
                                    : $perm->$col(@_);
    };

    my $prefs_col = "${type}_prefs";
    my $prefs = $loader->($prefs_col);
    $prefs;
}

sub save_prefs {
    my $self  = shift;
    my ($type, $args, $prefs)  = @_;
    $args ||= {};

    croak "Cannot save $type display prefs without blog_id or author_id "
          .' '.Dumper(\@_)
        unless $args->{blog_id}
            or $args->{author_id}
            or $type eq 'author';

    # croak "Cannot save $type display prefs without prefs".Dumper(\@_)
    #     unless $prefs;

    require MT::Permission;
    my $perm = MT::Permission->get_by_key({
        blog_id   => $args->{blog_id}   || 0,
        author_id => $args->{author_id} || 0
    });

    return 'Could not create permission record: '.MT::Permission->errstr
        unless $perm;

    my $loader = sub {
        my $col = shift;
        $perm->is_meta_column($col) ? $perm->meta($col, @_)
                                    : $perm->$col(@_);
    };

    my $prefs_col = "${type}_prefs";
    $loader->( $prefs_col, $prefs );
    my $rc = $perm->save
        or croak "Could not save $type display prefs: ".$perm->errstr;
    $rc;
}

sub meta_field_column_defs {
    return $_[0]->registry('object_types', 'permission') || {};
}

1;

__END__

