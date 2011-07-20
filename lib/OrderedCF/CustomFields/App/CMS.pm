package OrderedCF::CustomFields::App::CMS;

use strict;
use warnings;
use YAML;
use Data::Dumper;
use Carp qw( croak );

use Sub::Install;
use OrderedCF;

our ( $populate_field_loop_orig, $field_loop_orig );

sub override_methods {
    
    # Save references to native methods CustomFields::Util::field_loop and
    # CustomFields::App::CMS::populate_field_loop, returning if they cannot
    # be assigned.  This ensures activation only if CustomFields is installed
    return unless
        $field_loop_orig =
            eval {
                require CustomFields::Util;
                CustomFields::Util->can('field_loop');
            };

    return unless
        $populate_field_loop_orig =
            eval {
                require CustomFields::App::CMS;
                CustomFields::App::CMS->can('populate_field_loop');
            };

    # Install wrapper functions around the above.
    Sub::Install::reinstall_sub({
        code => 'field_loop',
        into => 'CustomFields::Util',
    });

    Sub::Install::reinstall_sub({
        code => 'populate_field_loop',
        into => 'CustomFields::App::CMS',
    });

    # This is also needed because field_loop is a utility function imported
    # into CustomFields::App::CMS from CustomFields::Util
    Sub::Install::reinstall_sub({
        code => 'field_loop',
        into => 'CustomFields::App::CMS',
    });

}

sub populate_field_loop {
    my ($cb, $app, $param, $tmpl) = @_;
    my $q         = $app->query;
    my $type      = $q->param('_type');
    my $plugin    = $cb->plugin;
    my $orderedcf = ref $plugin eq 'OrderedCF'  ? $plugin 
                                                : OrderedCF->instance;
    if ( $type eq 'entry' or $type eq 'page' ) {
        $populate_field_loop_orig->(@_);
    }
    else{

        # YAY DOM
        # Add the custom fields to the customizable_fields and custom_fields javascript variables
        # for Display Options toggline
        my $header = $tmpl->getElementById('header_include');
        my $html_head = $tmpl->createElement('setvarblock', { name => 'html_head', append => 1 });
        my $innerHTML = q{
        <script type="text/javascript">
        /* <![CDATA[ */
            <mt:loop name="field_loop"><mt:if name="required">default_fields.push('<mt:var name="field_id">');</mt:if>
            </mt:loop>
        /* ]]> */
        </script>
        };
        $html_head->innerHTML($innerHTML);
        $tmpl->insertBefore($html_head, $header);

        $populate_field_loop_orig->(@_);

        my $content_fields = $tmpl->getElementById('content_fields');
        my $beacon_tmpl
            = File::Spec->catdir($plugin->path, 'tmpl', 'field_beacon.tmpl');
        my $beacon
            = $tmpl->createElement('include', { name => $beacon_tmpl });
        $tmpl->insertAfter($beacon, $content_fields);
    }

    # Load user-specific prefs for $type on $blog_id
    my $blog_id   = $q->param('blog_id');
    my $author_id = eval { $app->user->id };
    my $args      = {
        $blog_id   ? (blog_id   => $blog_id)   : (),
        $author_id ? (author_id => $author_id) : (),
    };
    my $prefs     = $orderedcf->load_prefs( $type, $args );

    # If no prefs were loaded, load the blog default for $type
    if ( ! $prefs and $args->{author_id} ) {
        delete $args->{author_id};
        $prefs = $orderedcf->load_prefs( $type, $args );
    }
    return unless $prefs;

    # Convert prefs into a simple @field_order
    my (@field_order, %seen);
    if ( $type eq 'entry' or $type eq 'page' ) {
        ( $prefs, my $pos ) = split /\|/, $prefs;
        $app->_parse_entry_prefs( $prefs, $param, \@field_order );
        @field_order = grep { ! $seen{ $_->{name} }++ } @field_order
    }
    else {
        @field_order = @$prefs;
    }

    return unless @field_order;

    # Create an lookup index of all known fields keyed by field ID
    my %fields = map { $_->{field_id} => $_ } @{$param->{field_loop}}
        or return;

    # Tack all fields onto the end of @field_order to account for
    # hidden fields, which do not appear in the display prefs record
    # but must appear in the display options panel
    push( @field_order, ( map { {name => $_} } sort keys %fields ));

    # Dedupe @field_order and ensure all elements are consistent
    %seen = ();
    @field_order = grep { $_->{name} and ! $seen{$_->{name}}++ }
                    @field_order;

    # Convert @field_order into @ordered_loop using the lookup index
    # for field information
    my @ordered_loop = grep { defined }
                        map { $fields{$_->{name}} } @field_order;

    # Store reference to @ordered_loop as the new value for field_loop param
    $param->{field_loop} = \@ordered_loop;
}

sub field_loop {
    $field_loop_orig->(@_);
}


1;

__END__