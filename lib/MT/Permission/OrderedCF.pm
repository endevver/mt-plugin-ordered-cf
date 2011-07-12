# package MT::Permission::OrderedCF;
# 
# use strict;
# use base qw( MT::Permission );
# 
# __PACKAGE__->install_properties({
#     column_defs => {
#         %{ meta_field_column_defs() }
#     },
# });
# 
# # Add MT::Permission::OrderedCF meta fields to MT::Permission objects
# # (necessary to prevent MT errors when cloning blogs, posting comments)
# sub init_meta_fields {
#     my $props = MT->model('permission')->properties;
# print __PACKAGE__.'::init_meta_fields '.Dumper($props);
#     # $props->{meta} = 1;
#     # 
#     # my $ppkg = ;
#     # $ppkg->install_meta({ 
#     #     column_defs => {
#     #         %{ meta_field_column_defs() }
#     #     }
#     # });
# }
# 
# sub meta_field_column_defs {
#     my $type = 'permission';
#     my $plugin = MT->component('mt-plugin-ordered-cf');
#     my $perm_fields = $plugin->registry('object_types', $type) || {};
# 
#     my $ppkg = MT->model($type) or return 0;
#     delete $perm_fields->{plugin};
#     return $perm_fields;
#     
#     foreach my $field ( grep { $_ ne 'plugin' } keys %$perm_fields ) {
#         $ppkg->install_meta({ column_defs => {
#             $field => $perm_fields->{$field}
#         }});
#         print STDERR "INSTALLED meta column $field into MT::Permission\n";
#     }
#     return 1;
# }
# 
# 1;
