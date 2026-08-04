package Koha::Plugin::RebuildElasticSearch;

use Modern::Perl;
use base qw(Koha::Plugins::Base);
use C4::Context;
use C4::Members;
use C4::Auth;
use C4::Members::Messaging;
use C4::Context;
use Pod::Usage;
use Getopt::Long;
use Data::Dumper;
use File::Spec;
use LWP::Simple;
use Koha::DateUtils qw ( dt_from_string );
use XML::LibXML;
use Scalar::Util qw(looks_like_number);
use Error ':try';
use JSON;
use warnings;
use strict;

use feature 'say';

our $VERSION = 1.0;

our $metadata ={
    name   => 'Rebuild Elastic Search',
    author => 'Salah Ghedda, Hinemoea Viault',
    description => 'Execute the script "rebuild_elasticsearch.pl"',
    date_authored   => '2023-09-13',
    date_updated    => '2024-07-31',
    minimum_version => '22.05.00',
    maximum_version => undef,
    version         => '1.1',
};

sub run_command {
    my ($parameters, $global_outputs_ref, $path) = @_;
    my @outputs = `$path $parameters`;
    $$global_outputs_ref = join("\n", @outputs);
}

sub get_index_entries {

    my $xml_file_path = $ENV{KOHA_CONF};
    my $dom = XML::LibXML->load_xml(location => $xml_file_path);

    my ($index_name_element) = $dom->findnodes('//elasticsearch/index_name');
    my $server_element = $dom->findvalue('//elasticsearch/server');

    my $server = $server_element ? $server_element : "";
    my $index_name = $index_name_element ? $index_name_element->textContent : "";

    my $authorities_url = "http://${server}/${index_name}_authorities/_count/?pretty";
    my $biblios_url = "http://${server}/${index_name}_biblios/_count/?pretty";

    my $content_authorities = get($authorities_url) || "Failed to fetch authorities data";
    my $content_biblios = get($biblios_url) || "Failed to fetch biblios data";

    my $count_authorities = "N/A";  # Default value in case count is not found
    my $count_biblios = "N/A";      # Default value in case count is not found

    if ($content_authorities) {
        my $json = JSON->new->allow_nonref;
        my $data = $json->decode($content_authorities);

        if (exists $data->{count}) {
            $count_authorities = $data->{count};
        }
    }

    if ($content_biblios) {
        my $json = JSON->new->allow_nonref;
        my $data = $json->decode($content_biblios);

        if (exists $data->{count}) {
            $count_biblios = $data->{count};
        }
    }

    warn $server;
    warn $index_name;

    return ($server, $index_name, $count_authorities, $count_biblios);
}

sub new {
    my ( $class, $args ) = @_;
    $args->{'metadata'} = $metadata;
    my $self = $class->SUPER::new($args);
    return $self;
}

sub tool {
    my ($self, $args) = @_;
    my $cgi = $self->{'cgi'};

    my $global_outputs = "";

    if (uc($cgi->request_method()) eq 'POST')
    {
        my $commit = $cgi->param('commit');
        my $processes = $cgi->param('processes');
        my $bnumber = $cgi ->param('bnumber');
        my $authid = $cgi ->param('authid');

        my $delete = $cgi->param('delete') ? 1 : 0;
        my $reset = $cgi->param('reset') ? 1 : 0;
        my $descending = $cgi ->param('descending') ? 1 : 0;
        my $authorities = $cgi ->param('authorities') ? 1 : 0;
        my $biblios = $cgi ->param('biblios') ? 1 : 0;
        my $verbose = $cgi->param('verbose') ? 1 : 0;

        my $path = C4::Context->config("intranetdir") . "/misc/search_tools/rebuild_elasticsearch.pl";
        my @parameters;

        push @parameters, "--commit=$commit"        if looks_like_number($commit);
        push @parameters, "-p $processes"           if looks_like_number($processes);
        push @parameters, "-d"                      if $delete;
        push @parameters, "-r"                      if $reset;
        push @parameters, "--desc"                  if $descending;
        push @parameters, "-a"                      if $authorities;
        push @parameters, "-b"                      if $biblios;
        push @parameters, "-bn $bnumber"                     if looks_like_number($bnumber);
        push @parameters, "-ai $authid"                     if looks_like_number($authid);



        run_command("-v " . join(" ", @parameters), \$global_outputs, $path) if @parameters;
    }

    my ($server, $index_name, $count_authorities, $count_biblios) = $self->get_index_entries();

    my $preferedLanguage = C4::Languages::getlanguage($self->{'cgi'});
    my $template = $self->get_template({ file => 'RebuildElasticSearch_'. $preferedLanguage .'.tt' });
    $template->param(
        server            => $server,
        index_name        => $index_name,
        count_authorities => $count_authorities,
        count_biblios     => $count_biblios,
        global_outputs    => $global_outputs
    );

    print $cgi->header(-type => 'text/html', -charset => 'utf-8');
    print $template->output();
}




# Generic uninstall routine - removes the plugin from plugin pages listing
sub uninstall() {
    my ( $self, $args ) = @_;
}
1;
