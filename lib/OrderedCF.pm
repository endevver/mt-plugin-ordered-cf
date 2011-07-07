package OrderedCF;

use strict;
use warnings;
use YAML;
use Data::Dumper;

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