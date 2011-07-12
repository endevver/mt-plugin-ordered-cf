package OrderedCF;

use strict;
use warnings;
use YAML;
use Data::Dumper;
use Carp qw( croak );
use base qw( MT::Plugin );

sub post_init {
    my $cb = shift;
    my $plugin = shift;
    $cb->plugin->init_meta_fields(@_);
}

sub meta_field_column_defs {
    return $_[0]->registry('object_types', 'permission') || {};
}

sub init_meta_fields {
    my $self = shift;
    warn "self: $self" if ref $self ne 'OrderedCF';
    # my $plugin     = MT->component('mt-plugin-ordered-cf');
    my $perm_class = MT->model('permission');

    $perm_class->properties->{meta} = 1;
    $perm_class->install_meta({
        column_defs => $self->meta_field_column_defs()
    });

    eval "require ${perm_class}::Meta;";
    return 1;
}


sub load_prefs {
    my $self            = shift;
    my ($type, $args)   = @_;
    $args             ||= {};

    $type or croak "No object type specified for load_prefs";

    croak "Cannot load $type display prefs without blog_id or author_id "
         . Dumper(\@_)
         unless $args->{blog_id}
             or $args->{author_id}
             or $args->{type} eq 'author';

    require MT::Permission;
    my $perm = MT::Permission->load({
        blog_id   => $args->{blog_id}   || 0,
        author_id => $args->{author_id} || 0
    }) or return;

    # print STDERR 'load_prefs args: '.Dumper($args)."\n";
    # print STDERR 'load_prefs perm: '.Dumper($perm)."\n";

    my $loader = sub {
        my $col = shift;
        $perm->is_meta_column($col) ? $perm->meta($col, @_)
                                    : $perm->$col(@_);
    };

    my $prefs_col = "${type}_prefs";
    my $prefs = $loader->($prefs_col);
    # print STDERR 'load_prefs prefs: '.Dumper($prefs)."\n";
    $prefs;
}

sub save_prefs {
    my $self  = shift;
    my ($type, $args, $prefs)  = @_;
    $args ||= {};

    croak "Cannot save $type display prefs without blog_id or author_id "
          .' '.Dumper(\@_)
        unless $args->{blog_id}
            or $args->{author_id}
            or $type eq 'author';

    croak "Cannot save $type display prefs without prefs".Dumper(\@_)
        unless $prefs;

    require MT::Permission;
    my $perm = MT::Permission->get_by_key({
        blog_id   => $args->{blog_id}   || 0,
        author_id => $args->{author_id} || 0
    });

    return 'Could not create permission record: '.MT::Permission->errstr
        unless $perm;

    print STDERR 'save_display_prefs args: '.Dumper(\@_)."\n";

    my $loader = sub {
        my $col = shift;
        $perm->is_meta_column($col) ? $perm->meta($col, @_)
                                    : $perm->$col(@_);
    };

    my $prefs_col = "${type}_prefs";
    $loader->( $prefs_col, $prefs );
    my $rc = $perm->save
        or croak "Could not save $type display prefs: ".$perm->errstr;
    print STDERR 'save_display_prefs perm: '.Dumper($perm)."\n";
    $rc;
}

sub custom_cfield_order {
    my ( $app )  = shift;
    my $q        = $app->query;
    my $obj_type = $q->param('_type');
    my $user     = $app->user;
    my $author_id = $user->id if $user;
    my $blog_id  = $app->blog ? $app->blog->id : 0;

    require MT::Permission;

    require MT::PluginData;
    my $plugindata = MT::PluginData->get_by_key({
        plugin => 'CustomFields',
        key => "field_order_$author_id"
    });

    my $data = $plugindata->data || {};
    $data->{$blog_id} ||= {};

    my $order = $data->{$blog_id}->{$obj_type};

}

sub default_cfield_order {
    my ( $app )  = shift;
    my $q        = $app->query;
    my $obj_type = $q->param('_type');
    my $user     = $app->user;
    my $blog_id  = $app->blog ? $app->blog->id : 0;

    my $prefs = load_prefs({ type => $obj_type, blog_id => $blog_id });

    # require MT::PluginData;
    # my $plugindata = MT::PluginData->get_by_key({
    #     plugin => 'CustomFields',
    #     key => "field_order_$author_id"
    # });
    # 
    # my $data = $plugindata->data || {};
    # $data->{$blog_id} ||= {};
    # 
    # my $order = $data->{$blog_id}->{$obj_type};
}

# $app->_parse_entry_prefs( $prefs, \%param, \my @custom_fields );
# MT::App::CMS::template_param.list_field
sub insert_orderedcf_link {
    my ($cb, $app, $param, $tmpl) = @_;
    my $q   = $app->query;
    my $blog_id = $q->param('blog_id');
    my $hint;
    if ( $q->param('filter_key') ) {
        my $header = $tmpl->getElementById('header_include');
        my $html_head = $tmpl->createElement(
            'setvarblock', { name => 'html_head', append => 1 });
        my $innerHTML = q{
    <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js"></script><script type="text/javascript" src="/mte/plugins/OrderedCF/static/OrderedCF.js"></script>};
        $html_head->innerHTML($innerHTML);
        $tmpl->insertBefore($html_head, $header);
        $hint = ' &nbsp; &nbsp; <em>Hint: To customize the blog\'s default field order, just drag the rows.</em>';
    }
    else {
        $hint = ' &nbsp; &nbsp; <em>Hint: To customize the blog\'s default field order, select a quickfilter.</em>';
    }

    my $head = $tmpl->getElementsByName('content_header')->[0];
    ( my $html = $head->innerHTML() )
        =~ s{ (</li>) }{ $hint $1 }smx;
    $head->innerHTML($html);
}

sub mode_order_field {
    my ( $app ) = shift;

}
1;