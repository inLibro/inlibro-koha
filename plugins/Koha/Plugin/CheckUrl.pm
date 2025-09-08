package Koha::Plugin::Com::Inlibro::CheckUrl;

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

our $VERSION = 1.0;

our $metadata = {
    name   => 'CheckUrl',
    author => 'Alexandre Noël',
    description => 'Execute the script "check-url-quick.pl"',
    date_authored   => '2024-08-15',
    date_updated    => '2024-08-15',
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
    my $cgi      = $self->{'cgi'};
    my $locale = $cgi->cookie('KohaOpacLanguage');

    # Execute the script and capture the output
    my $path = C4::Context->config("intranetdir") . "/misc/cronjobs/check-url-quick.pl --html --host ' '";
    my $script_output = qx($path);

    # Find locale-appropriate template
    my $template = undef;
    eval {
        $template =
          $self->get_template( { file => "result_" . $locale . ".tt" } );
    };
    if ( !$template ) {
        $locale = substr $locale, 0, 2;
        eval {
            $template = $self->get_template( { file => "result_$locale.tt" } );
        };
    }
    $template = $self->get_template( { file => 'result.tt' } ) unless $template;

    # Pass the script output to the template
    $template->param( script_output => $script_output );

    print $cgi->header( -type => 'text/html', -charset => 'utf-8' );
    print $template->output();
}


sub PageHome {
    my ( $self, $args ) = @_;
    my $cgi    = $self->{'cgi'};
    my $locale = $cgi->cookie('KohaOpacLanguage');

    # Find locale-appropriate template
    my $template = undef;
    eval {
        $template =
          $self->get_template( { file => "home_" . $locale . ".tt" } );
    };
    if ( !$template ) {
        $locale = substr $locale, 0, 2;
        eval {
            $template = $self->get_template( { file => "home_$locale.tt" } );
        };
    }
    $template = $self->get_template( { file => 'home.tt' } ) unless $template;
    print $cgi->header( -type => 'text/html', -charset => 'utf-8' );
    print $template->output();
}

#Supprimer le plugin avec toutes ses données
sub uninstall() {
    my ( $self, $args ) = @_;
    return 1;
}

1;
