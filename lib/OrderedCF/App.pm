package OrderedCF::App;

use strict;
use warnings;
use YAML;
use Data::Dumper;
use Carp qw( croak );

use base qw( MT::App::CMS );

sub mode_save_prefs {
    my $app          = shift;
    my $q            = $app->query;
    my $blog_default = $q->param('set_blog_default');
    my $blog_id      = $q->param('blog_id') || 0;
    my $author_id    = $blog_default ? 0 : eval { $app->user->id };
    my $plugin       = OrderedCF->instance();
    my $perms        = $app->permissions
      or return $app->errtrans("No permissions");

    $app->validate_magic() or return;

    return $app->errtrans('Bad author ID') unless defined $author_id;

    my $prefs = __PACKAGE__->_prefs_from_app_params();

    $plugin->save_prefs(
        $q->param('_type'),
        {
            $blog_id    ? (blog_id => $blog_id)      : (),
            $author_id  ? (author_id => $author_id ) : ()
        },
        $prefs,
    );

    $app->send_http_header("text/json");
    return "true";
}

sub insert_blog_default_option {
    my ($cb, $app, $param, $tmpl) = @_;
    my $reset = $tmpl->getElementById('reset_display_options')
        or return;

    my $blog_default = $tmpl->createElement(
        'app:setting',
        {
            id => 'blog_default_options',
            # label => 'Blog<br />default',
            label_class => 'display-options',
        }
    );
    $tmpl->insertBefore($blog_default, $reset);

    $blog_default->innerHTML(q{
            <ul>
                <li><input type="checkbox" name="set_blog_default" id="set-blog-default" value="1" /> Save as blog default?</li>
            </ul>
    });
}

sub remove_entry_display_cfg {
    my ($cb, $app, $param, $tmpl) = @_;
    my $field_cfg = $tmpl->getElementById('default-field-settings');
    $field_cfg->setAttribute( 'shown' => 0 );
}

sub replace_prefs_save_mode {
    my ( $cb, $app, $tmpl ) = @_;
    my $pat     = q{__mode=save_entry_prefs'};
    my $replace = q{__mode=orderedcf_save_prefs}
                . q{&set_blog_default='}
                . q{+(document.getElementById('set-blog-default').checked ? 1 : 0) };
    $$tmpl =~ s{$pat}{$replace}g;
}

sub _prefs_from_app_params {
    my $self        = shift;
    my $app         = MT->instance;
    my $q           = $app->query;
    my $object_type = $q->param('_type');
    my $type        = $q->param( $object_type.'_prefs' );
    my %fields;
    if ( $type && lc $type ne 'custom' ) {
        $fields{$type} = 1;
    }
    else {
        $fields{$_} = 1 foreach $q->param('custom_prefs');
    }
    if ( my $body_height = $q->param('text_height') ) {
        $fields{'body'} = $body_height;
    }
    my $prefs = '';
    foreach ( keys %fields ) {
        $prefs .= ',' if $prefs ne '';
        $prefs .= $_;
        $prefs .= ':' . $fields{$_} if $fields{$_} > 1;
    }
    if ( $type && lc $type eq 'custom' ) {
        my @fields = split /,/, $q->param('custom_prefs');
        foreach (@fields) {
            $prefs .= ',' if $prefs ne '';
            $prefs .= $_;
        }
    }
    $prefs .= '|' . $q->param('bar_position') if $q->param('bar_position');
    $prefs;
}

1;
