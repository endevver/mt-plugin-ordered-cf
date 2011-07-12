#!/usr/bin/perl
package Test::OrderedCF::Setup;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use base qw( Test::OrderedCF );

use Test::More tests => 3;

# Instantiate and initialize test object
my $test = __PACKAGE__->new();
$test->init();

# Check for test blog
my $blog = $test->blog();
isa_ok( $blog, 'MT::Blog', "Test blog");

# Check for test users
my $users = $test->users() || [];
is( @$users, 1, "One test user");

is( MT::Permission->has_meta(), 1, "MT::Permission has meta" );
diag explain MT::Permission->properties;

# diag explain MT::Author->properties;

$test->finish();


