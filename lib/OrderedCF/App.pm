package OrderedCF::App;

use strict;
use warnings;
use YAML;
use Data::Dumper;
use Carp qw( croak );

use base qw( MT::App::CMS );

sub mode_save_prefs {
    my $app    = shift;
    my $q      = $app->query;
    my $plugin = OrderedCF->instance();
    my $perms  = $app->permissions
      or return $app->errtrans("No permissions");

    $app->validate_magic() or return;

    my $prefs = __PACKAGE__->_prefs_from_app_params();
    my $col   = $q->param('_type').'_prefs';
    $perms->can($col)
        or return $app->errtrans('Invalid request');
    
    $perms->$col($prefs);
    $perms->save
      or return $app->errtrans( "Saving permissions failed: [_1]",
                                $perms->errstr );
    $app->send_http_header("text/json");
    return "true";
}


sub remove_entry_display_cfg {
    my ($cb, $app, $param, $tmpl) = @_;
    my $field_cfg = $tmpl->getElementById('default-field-settings');
    $field_cfg->setAttribute( 'shown' => 0 );
    print STDERR Dumper($field_cfg);
}

sub replace_prefs_save_mode {
    my ( $cb, $app, $tmpl ) = @_;
    $$tmpl =~ s{__mode=save_entry_prefs}{__mode=orderedcf_save_prefs}g;
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
