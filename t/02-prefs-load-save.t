#!/usr/bin/perl
package Test::OrderedCF::Prefs::LoadSave;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use base qw( Test::OrderedCF );
use Data::Dumper;

use Test::More tests => 7;

# Instantiate and initialize test object
my $test = __PACKAGE__->new();
$test->init();

my $app = MT->instance;

my $more_props = MT->registry('object_types');
# die Dumper(MT::Permission->install_properties);

my $plugin = $app->component('mt-plugin-ordered-cf');
# diag Dumper($plugin);

isa_ok( $plugin, 'MT::Plugin' )
    or diag 'Could not load plugin: '.MT->errstr;

my $type = 'page';
my $args = { blog_id => $test->blog->id };
$plugin->save_prefs( $type, $args, undef );

my $prefs = $plugin->load_prefs( $type, $args );
is( $prefs, undef, "No page prefs" );
$prefs = 'title,body';

is( $plugin->save_prefs( $type, $args, $prefs ), 1,
    "Saved blog default $type prefs" );

is( $plugin->load_prefs( $type, $args ), $prefs,
    "Loaded saved blog default $type prefs");

########################################
$type = 'category';
$args->{author_id} = $test->user->id;
$plugin->save_prefs( $type, $args, undef );

$prefs = $plugin->load_prefs( $type, $args );
is( $prefs, undef, "No author $type prefs" );
$prefs = 'label,basename,description';

is( $plugin->save_prefs( $type, $args, $prefs ), 1,
    "Saved author $type prefs" );

is( $plugin->load_prefs( $type, $args ), $prefs,
    "Loaded saved author $type prefs");

$test->finish();


