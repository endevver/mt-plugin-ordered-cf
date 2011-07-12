package OrderedCF::App;

use strict;
use warnings;
use YAML;
use Data::Dumper;
use Carp qw( croak );

our ($field_loop_orig, $populate_field_loop_orig);

sub init_app {
    my $app = shift;

    # Save references to native methods CustomFields::Util::field_loop and
    # CustomFields::App::CMS::populate_field_loop, returning if they cannot
    # be assigned.  This ensures activation only if CustomFields is installed
    return unless
        $field_loop_orig = eval {
            require CustomFields::Util;
            CustomFields::Util->can('field_loop');
        };
    return unless
        $populate_field_loop_orig = eval {
            require CustomFields::App::CMS;
            CustomFields::App::CMS->can('populate_field_loop');
        };

    # Install wrapper functions around the above.
    require Sub::Install;
    Sub::Install::reinstall_sub( {
                                   code => 'field_loop',
                                   into => 'CustomFields::Util',
                                 }
                                );

    Sub::Install::reinstall_sub( {
                                   code => 'populate_field_loop',
                                   into => 'CustomFields::App::CMS',
                                 }
                                );

    # This is also needed because field_loop is a utility function imported
    # into CustomFields::App::CMS from CustomFields::Util
    Sub::Install::reinstall_sub( {
                                   code => 'field_loop',
                                   into => 'CustomFields::App::CMS',
                                 }
                                );
}

sub populate_field_loop {
    my ($cb, $app, $param, $tmpl) = @_;


    my @field_order = qw(
        title
        text
        excerpt
        tags
        keywords
        customfield_swear_on_your_mothers_grave
        customfield_awesomesauce
    );

    # my $plugin = $cb->plugin;
    # my $q = $app->param;
    #
    # my $mode = $app->mode;
    # my $blog_id = $q->param('blog_id');
    # my $object_id = $q->param('id');
    # my $object_type = $q->param('_type');
    # my $is_entry = ($object_type eq 'entry' || $object_type eq 'page' || $mode eq 'cfg_entry');
    #
    # my %param = (
    #     $blog_id ? ( blog_id => $blog_id ) : (),
    #     ($mode eq 'cfg_entry') ? ( object_type => 'entry' ) :
    #             ( object_type => $object_type, object_id => $object_id ),
    #     params => $param,
    # );
    # my $loop = $param->{field_loop};

    # my @return =
        $populate_field_loop_orig->(@_);
    # print STDERR "\n\n\n\n========================\n";
    # print STDERR 'populate_field_loop_orig return: '.Dumper(\@return)."\n";
    # my $field_pat = qr/^(disp_prefs_.*custom|field_loop)/;
    # print STDERR Dumper({
    #     map {
    #             m/$field_pat/ ? ( $_ => $param->{$_} ) : ()
    #         } keys %$param
    # })."\n";

    my %fields       = map { $_->{field_id} => $_ } @{$param->{field_loop}};
    my @ordered_loop = map { $fields{$_} } @field_order;

    $param->{field_loop} = \@ordered_loop;
}

sub field_loop {
    my (%param) = @_;
    my $sorted = $field_loop_orig->(@_);
    # print STDERR "\n\n\n\n========================\n";
    # print STDERR 'field_loop params: '  .Dumper(\%param), "\n\n",
    #              '$sorted fields: '     .Dumper( $sorted )."\n";
    $sorted;
}

sub _parse_entry_prefs {
    my $app = shift;
    my ( $prefs, $param, $fields ) = @_;

    my @p = split /,/, $prefs;
    for my $p (@p) {
        if ( $p =~ m/^(.+?):(\d+)$/ ) {
            my ( $name, $num ) = ( $1, $2 );
            if ($num) {
                $param->{ 'disp_prefs_height_' . $name } = $num;
            }
            $param->{ 'disp_prefs_show_' . $name } = 1;
            push @$fields, { name => $name };
        }
        else {
            $p = 'Default' if lc($p) eq 'basic';
            if ( ( lc($p) eq 'advanced' ) || ( lc($p) eq 'default' ) ) {
                $param->{ 'disp_prefs_' . $p } = 1;
                foreach my $def (
                    qw( title body category tags keywords feedback publishing assets )
                    )
                {
                    $param->{ 'disp_prefs_show_' . $def } = 1;
                    push @$fields, { name => $def };
                }
                if ( lc($p) eq 'advanced' ) {
                    foreach my $def (qw(excerpt feedback)) {
                        $param->{ 'disp_prefs_show_' . $def } = 1;
                        push @$fields, { name => $def };
                    }
                }
            }
            else {
                $param->{ 'disp_prefs_show_' . $p } = 1;
                push @$fields, { name => $p };
            }
        }
    }
}


1;
