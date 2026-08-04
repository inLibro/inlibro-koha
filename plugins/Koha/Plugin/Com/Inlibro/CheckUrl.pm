package Koha::Plugin::Com::Inlibro::CheckUrl;

use Modern::Perl;
use base qw(Koha::Plugins::Base);
use C4::Context;
use Pod::Usage;
use Getopt::Long;
use warnings;
use strict;

our $VERSION = 2.1;

our $metadata = {
    name   => 'CheckUrl',
    author => 'Alexandre Noël, Noah Tremblay, Chris Mathevet',
    description => 'Execute the script "check-url-quick.pl"',
    date_authored   => '2024-08-15',
    date_updated    => '2026-08-04',
    minimum_version => '22.05.00',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;
    $args->{'metadata'} = $metadata;
    my $self = $class->SUPER::new($args);
    return $self;
}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    if ($cgi->param('action')){
        $self->PageResult();
    }else{
        $self->PageHome();
    }
}

sub PageResult {
    my ( $self, $args ) = @_;

    # Execute the script and capture the output
    my $path = C4::Context->config("intranetdir") . "/misc/cronjobs/check-url-quick.pl --html --host ' '";
    my $script_output = qx($path);

    my $template = $self->get_template( { file => 'result.tt' } );

    # Pass the script output to the template
    $template->param( script_output => $script_output );

    $self->output_html($template->output());
    return;
}


sub PageHome {
    my ( $self, $args ) = @_;

    my $template = $self->get_template( { file => 'home.tt' } );

    $self->output_html($template->output());
    return;
}

#Supprimer le plugin avec toutes ses données
sub uninstall() {
    my ( $self, $args ) = @_;
    return 1;
}

1;
