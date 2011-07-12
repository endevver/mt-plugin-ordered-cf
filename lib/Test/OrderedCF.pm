package Test::OrderedCF;

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use base qw( MT::Test::Base );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    $self->init_test_blog();
    $self->init_test_user();
    $self->init_data();
}

sub init_data {
    my $self = shift;
    my $fh = shift;
    my $from = $fh || join('::', __PACKAGE__, 'DATA');
    my $data;
    { local $/; $data = <$from>; }
    close $from;
    $_[0]->SUPER::init_data( $data ) if $data =~ m{\w};
}

sub finish {
    
}

1;

__DATA__

