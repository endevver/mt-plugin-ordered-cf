#!/usr/bin/perl
package Test::OrderedCF::Compile;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

our @modules;
BEGIN {
    @modules = qw(
        OrderedCF
        OrderedCF::App
        OrderedCF::CustomFields::App::CMS
        OrderedCF::Upgrade
        Test::OrderedCF
    );
}

use Test::More tests => scalar @modules;

use_ok($_) foreach @modules;