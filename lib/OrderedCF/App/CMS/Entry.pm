package OrderedCF::CMS::Entry;

sub param_edit_entry {
    my ($eh, $app, $param, $tmpl) = @_;
    my $blog = $app->blog() or return;
    ###l4p $logger ||= MT::Log::Log4perl->new(); $logger->trace();

    ###l4p $logger->debug('disp_prefs_default_fields: ',
    ###l4p    l4mtdump($param->{disp_prefs_default_fields}));

    my $key = sub { $_[0]->{basename} || $_[0]->{field_id} };
    
    ###l4p $logger->debug('field_loop: ', l4mtdump($param->{field_loop}));
    my %field_loop_fields
        = map { ( $key->($_) => $_ ) }  @{ $param->{field_loop} };
    ###l4p $logger->debug('%field_loop_fields: ', l4mtdump(\%field_loop_fields));

    my $field_spec;
    my $blog_type = $blog->meta('filmcritic_blog');
    ###l4p $logger->debug("We have the $blog_type blog");

    my $fcblog_class = 'FilmCritic::Blog::'.$blog_type;
    eval "require $fcblog_class;";
    $@ and die $@;

    my $fcblog  = $fcblog_class->new( $param->{blog_name} );
    $field_spec = $fcblog_class->field_meta_data();

    my (%ordered, @unordered);
    while (my ($fkey, $fspec) = each %{ $field_spec } ) {
        next unless $fspec->{order} || $fspec->{field};
             
        my $fieldbase = $fspec->{attr} || $fspec->{field}{basename};
        if ( ! $fspec->{order} ) {
            push @unordered, $fieldbase;
            next;
        }
        $ordered{ $fieldbase } = $fspec->{order};
    }
    ###l4p $logger->debug('%ordered: ', l4mtdump(\%ordered));
    my $field_order = join(',', 
        (sort { $ordered{$a} <=> $ordered{$b}} keys %ordered),
        @unordered
    );
    ###l4p $logger->debug('$field_order: ', l4mtdump($field_order));

    my @sorted_fields
        = grep { defined }
            map { $field_loop_fields{$_} || undef } 
             (sort { $ordered{$a} <=> $ordered{$b}} keys %ordered);
    ###l4p $logger->debug('@sorted_fields: ', l4mtdump(\@sorted_fields));

    # Set the template loop parameter with the sorted custom fields
    $param->{field_loop} = \@sorted_fields;
}

1;