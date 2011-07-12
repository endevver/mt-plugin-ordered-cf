package OrderedCF::Upgrade;

use strict;
use warnings;
use Data::Dumper;

sub create_table_permission_meta {
    my $app        = shift;
    my $plugin     = MT->component('mt-plugin-ordered-cf');
    $plugin->init_meta_fields();
    $app->check_schema();
}

1;