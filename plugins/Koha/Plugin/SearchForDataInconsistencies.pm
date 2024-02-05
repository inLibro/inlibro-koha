package Koha::Plugin::SearchForDataInconsistencies;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

#J'ajouter :

use Koha::Script;
use Koha::AuthorisedValues;
use Koha::Authorities;
use Koha::Biblios;
use Koha::BiblioFrameworks;
use Koha::Biblioitems;
use Koha::Items;
use Koha::ItemTypes;
use Koha::Patrons;
use Modern::Perl;
use strict;
use warnings;
use Data::Dumper;
use CGI;
use utf8;
use DateTime;
use base qw(Koha::Plugins::Base);
use C4::Auth;
use C4::Context;

our $VERSION  = 1.1;
our $metadata = {
    name            => 'SearchForDataInconsistencies',
    author          => 'Phan Tung Bui',
    description     => 'Generates data inconsistenceies',
    date_authored   => '2024-01-12',
    date_updated    => '2023-01-15',
    minimum_version => '3.20',
    maximum_version => undef,
    version         => $VERSION,
};

our $dbh = C4::Context->dbh();

my @result_presets = (
    {
        id    => 'Invalid items branch',
        title => "Check items branch"
    },
    {
        id    => 'Invalid items auth head',
        title => "Check items auth header"
    },
    {
        id    => 'Invalid items status',
        title => "Check items status"
    },
    {
        id    => 'Invalid items framework',
        title => "Check items framework"
    },
    {
        id    => 'Invalid items title',
        title => "Check items title"
    },
    {
        id    => 'Invalid age category',
        title => "Check age for category"
    }

);

my %method_map = (
    'Invalid items branch'    => \&check_items_branch,
    'Invalid items auth head' => \&check_items_auth_header,
    'Invalid items status'    => \&check_items_status,
    'Invalid items framework' => \&check_items_framework,
    'Invalid items title'     => \&check_items_title,
    'Invalid age category'    => \&check_age_for_category
);

sub new {
    my ( $class, $args ) = @_;
    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    #bless $self,$class;
    return $self;
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
    $template->param( result_presets => \@result_presets );
    print $cgi->header( -type => 'text/html', -charset => 'utf-8' );
    print $template->output();
}

sub PageResult {
    my ( $self, $args ) = @_;
    my $cgi      = $self->{'cgi'};
    my $locale   = $cgi->cookie('KohaOpacLanguage');
    my $template = undef;

    $template = $self->get_template( { file => 'result.tt' } ) unless $template;

    #For every checked preset, generate the appropriate message :
    my @main_messages;
    for my $key ( $cgi->param('checkbox-preset') ) {
        if ( exists $method_map{$key} ) {
            my $method_sub = sub {
                my @messages = $method_map{$key}->();
                return { method_name => $key, messages => \@messages };
            };

            push @main_messages, $method_sub->(),
              'BLACK_LINE';    # For separating each paragraph
        }
    }

    $template->param( main_messages => \@main_messages );

    print $cgi->header( -type => 'text/html', -charset => 'utf-8' );
    print $template->output();

}

sub tool {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};
    if ( $cgi->param('action') ) {
        $self->PageResult();
    }
    else {
        $self->PageHome();
    }

}

sub check_items_branch {
    my @messages;

    my $items = Koha::Items->search(
        { -or => { homebranch => undef, holdingbranch => undef } } );
    if ( $items->count ) {
        push @messages,
          "Not defined items.homebranch and/or items.holdingbranch";
    }
    while ( my $item = $items->next ) {
        if ( not $item->homebranch and not $item->holdingbranch ) {
            push @messages,
              sprintf(
"Item with itemnumber=%s does not have homebranch and holdingbranch defined",
                $item->itemnumber );
        }
        elsif ( not $item->homebranch ) {
            push @messages,
              sprintf(
                "Item with itemnumber=%s does not have homebranch defined",
                $item->itemnumber );
        }
        else {
            push @messages,
              sprintf(
                "Item with itemnumber=%s does not have holdingbranch defined",
                $item->itemnumber );
        }
    }
    if ( $items->count ) {
        push @messages,
          "Edit these items and set valid homebranch and/or holdingbranch";
    }
    if ( !@messages ) {
        @messages = "All items have home branch and holding branch";
    }
    return @messages;
}

sub check_items_auth_header {
    my @messages;

    # No join possible, FK is missing at DB level
    my @auth_types = Koha::Authority::Types->search->get_column('authtypecode');
    my $authorities = Koha::Authorities->search(
        { authtypecode => { 'not in' => \@auth_types } } );
    if ( $authorities->count ) {
        push @messages, "Invalid auth_header.authtypecode";
    }
    while ( my $authority = $authorities->next ) {
        push @messages,
          sprintf "Authority with authid=%s does not have a code defined (%s)",
          $authority->authid, $authority->authtypecode;
    }
    if ( $authorities->count ) {
        push @messages,
          "Go to 'Home › Administration › Authority types' to define them";
    }
    if ( !@messages ) { @messages = "All items have auth_header"; }
    return @messages;
}

#-------------------------------------------------------------------------------------------------
sub check_items_status {
    my @messages;
    if ( C4::Context->preference('item-level_itypes') ) {
        my $items_without_itype =
          Koha::Items->search( { -or => [ itype => undef, itype => '' ] } );
        if ( $items_without_itype->count ) {
            push @messages, "Items do not have itype defined";
            while ( my $item = $items_without_itype->next ) {
                if ( defined $item->biblioitem->itemtype
                    && $item->biblioitem->itemtype ne '' )
                {
                    push @messages,
                      sprintf
"Item with itemnumber=%s does not have a itype value, biblio's item type will be used (%s)",
                      $item->itemnumber, $item->biblioitem->itemtype;
                }
                else {
                    push @messages,
                      sprintf
"Item with itemnumber=%s does not have a itype value, additionally no item type defined for biblionumber=%s",
                      $item->itemnumber, $item->biblioitem->biblionumber;
                }
            }
            push @messages,
"The system preference item-level_itypes expects item types to be defined at item level";
        }
    }
    else {
        my $biblioitems_without_itemtype =
          Koha::Biblioitems->search( { itemtype => undef } );
        if ( $biblioitems_without_itemtype->count ) {
            push @messages, "Biblioitems do not have itemtype defined";
            while ( my $biblioitem = $biblioitems_without_itemtype->next ) {
                push @messages,
                  sprintf
"Biblioitem with biblioitemnumber=%s does not have a itemtype value",
                  $biblioitem->biblioitemnumber;
            }
            push @messages,
              sprintf
"The system preference item-level_itypes expects item types to be defined at biblio level";
        }
    }

    my @itemtypes = Koha::ItemTypes->search->get_column('itemtype');
    if ( C4::Context->preference('item-level_itypes') ) {
        my $items_with_invalid_itype = Koha::Items->search(
            {
                -and => [
                    itype => { not_in => \@itemtypes },
                    itype => { '!='   => '' }
                ]
            }
        );
        if ( $items_with_invalid_itype->count ) {
            push @messages, "Items have invalid itype defined";
            while ( my $item = $items_with_invalid_itype->next ) {
                push @messages,
                  sprintf
"Item with itemnumber=%s, biblionumber=%s does not have a valid itype value (%s)",
                  $item->itemnumber, $item->biblionumber, $item->itype;
            }
            push @messages,
              sprintf
"The items must have a itype value that is defined in the item types of Koha (Home › Administration › Item types administration)";
        }
    }
    else {
        my $biblioitems_with_invalid_itemtype = Koha::Biblioitems->search(
            { itemtype => { not_in => \@itemtypes } } );
        if ( $biblioitems_with_invalid_itemtype->count ) {
            push @messages, sprintf "Biblioitems do not have itemtype defined";
            while ( my $biblioitem = $biblioitems_with_invalid_itemtype->next )
            {
                push @messages,
                  sprintf
"Biblioitem with biblioitemnumber=%s does not have a valid itemtype value",
                  $biblioitem->biblioitemnumber;
            }
            push @messages,
              sprintf
"The biblioitems must have a itemtype value that is defined in the item types of Koha (Home › Administration › Item types administration)";
        }
    }

    my ( @decoding_errors, @ids_not_in_marc );
    my $biblios = Koha::Biblios->search;
    my ( $biblio_tag, $biblio_subfield ) =
      C4::Biblio::GetMarcFromKohaField("biblio.biblionumber");
    my ( $biblioitem_tag, $biblioitem_subfield ) =
      C4::Biblio::GetMarcFromKohaField("biblioitems.biblioitemnumber");
    while ( my $biblio = $biblios->next ) {
        my $record = eval { $biblio->metadata->record; };
        if ($@) {
            push @decoding_errors, $@;
            next;
        }
        my ( $biblionumber, $biblioitemnumber );
        if ( $biblio_tag < 10 ) {
            my $biblio_control_field = $record->field($biblio_tag);
            $biblionumber = $biblio_control_field->data
              if $biblio_control_field;
        }
        else {
            $biblionumber = $record->subfield( $biblio_tag, $biblio_subfield );
        }
        if ( $biblioitem_tag < 10 ) {
            my $biblioitem_control_field = $record->field($biblioitem_tag);
            $biblioitemnumber = $biblioitem_control_field->data
              if $biblioitem_control_field;
        }
        else {
            $biblioitemnumber =
              $record->subfield( $biblioitem_tag, $biblioitem_subfield );
        }
        if ( $biblionumber != $biblio->biblionumber ) {
            push @ids_not_in_marc,
              {
                biblionumber         => $biblio->biblionumber,
                biblionumber_in_marc => $biblionumber,
              };
        }
        if ( $biblioitemnumber != $biblio->biblioitem->biblioitemnumber ) {
            push @ids_not_in_marc,
              {
                biblionumber     => $biblio->biblionumber,
                biblioitemnumber => $biblio->biblioitem->biblioitemnumber,
                biblioitemnumber_in_marc => $biblionumber,
              };
        }
    }
    if (@decoding_errors) {
        push @messages, sprintf "Bibliographic records have invalid MARCXML";
        foreach my $error (@decoding_errors) {
            push @messages, "\t* $error";
        }
        push @messages,
          sprintf
"The bibliographic records must have a valid MARCXML or you will face encoding issues or wrong displays";
    }
    if (@ids_not_in_marc) {
        push @messages,
          sprintf
"Bibliographic records have MARCXML without biblionumber or biblioitemnumber";
        for my $id (@ids_not_in_marc) {
            if ( exists $id->{biblioitemnumber} ) {
                push @messages,
                  sprintf(
q{Biblionumber %s has biblioitemnumber '%s' but should be '%s' in %s$%s},
                    $id->{biblionumber},             $id->{biblioitemnumber},
                    $id->{biblioitemnumber_in_marc}, $biblioitem_tag,
                    $biblioitem_subfield,
                  );
            }
            else {
                push @messages,
                  sprintf(
                    q{Biblionumber %s has '%s' in %s$%s},
                    $id->{biblionumber}, $id->{biblionumber_in_marc},
                    $biblio_tag,         $biblio_subfield,
                  );
            }
        }
        push @messages,
          sprintf
"The bibliographic records must have the biblionumber and biblioitemnumber in MARCXML";
    }
    push @messages, @decoding_errors;

    if ( !@messages ) { @messages = "All items have normal status" }
    return @messages;
}

sub check_items_framework {
    my @messages;
    my @framework_codes =
      Koha::BiblioFrameworks->search()->get_column('frameworkcode');
    push @framework_codes,
      "";    # The default is not stored in frameworks, we need to force it

    my $invalid_av_per_framework = {};
    foreach my $frameworkcode (@framework_codes) {

        # We are only checking fields that are mapped to DB fields
        my $msss = Koha::MarcSubfieldStructures->search(
            {
                frameworkcode    => $frameworkcode,
                authorised_value => {
                    '!=' => [ -and => ( undef, '' ) ]
                },
                kohafield => {
                    '!=' => [ -and => ( undef, '' ) ]
                }
            }
        );
        while ( my $mss = $msss->next ) {
            my $kohafield = $mss->kohafield;
            my $av        = $mss->authorised_value;
            next
              if grep { $_ eq $av }
              qw( branches itemtypes cn_source );    # internal categories

            my $avs = Koha::AuthorisedValues->search_by_koha_field(
                {
                    frameworkcode => $frameworkcode,
                    kohafield     => $kohafield,
                }
            );
            my $tmp_kohafield = $kohafield;
            if ( $tmp_kohafield =~ /^biblioitems/ ) {
                $tmp_kohafield =~ s|biblioitems|biblioitem|;
            }
            else {
                $tmp_kohafield =~ s|items|me|;
            }

            # replace items.attr with me.attr

            # We are only checking biblios with items
            my $items = Koha::Items->search(
                {
                    $tmp_kohafield => {
                        -not_in => [ $avs->get_column('authorised_value'), '' ],
                        '!='    => undef,
                    },
                    'biblio.frameworkcode' => $frameworkcode
                },
                { join => [ 'biblioitem', 'biblio' ] }
            );
            if ( $items->count ) {
                $invalid_av_per_framework->{$frameworkcode}->{$av} =
                  { items => $items, kohafield => $kohafield };
            }
        }
    }
    if (%$invalid_av_per_framework) {
        push @messages, sprintf "Wrong values linked to authorised values";
        for my $frameworkcode ( keys %$invalid_av_per_framework ) {
            while ( my ( $av_category, $v ) =
                each %{ $invalid_av_per_framework->{$frameworkcode} } )
            {
                my $items     = $v->{items};
                my $kohafield = $v->{kohafield};
                my ( $table, $column ) = split '\.', $kohafield;
                my $output;
                while ( my $i = $items->next ) {
                    my $value =
                        $table eq 'items'  ? $i->$column
                      : $table eq 'biblio' ? $i->biblio->$column
                      :                      $i->biblioitem->$column;
                    $output .= " {" . $i->itemnumber . " => " . $value . "}\n";
                }
                push @messages,
                  sprintf(
"The Framework *%s* is using the authorised value's category *%s*, "
                      . "but the following %s do not have a value defined ({itemnumber => value }):\n%s",
                    $frameworkcode, $av_category, $kohafield, $output );
            }
        }
    }
    if ( !@messages ) { @messages = "All items have framework" }
    return @messages;
}

sub check_items_title {
    my @messages;
    my $biblios = Koha::Biblios->search(
        {
            -or => [
                title => '',
                title => undef,
            ]
        }
    );
    if ( $biblios->count ) {
        my ( $title_tag, $title_subtag ) =
          C4::Biblio::GetMarcFromKohaField('biblio.title');
        my $title_field = $title_tag // '';
        $title_field .= '$' . $title_subtag if $title_subtag;
        push @messages, sprintf "Biblio without title $title_field";
        while ( my $biblio = $biblios->next ) {
            push @messages,
              sprintf "Biblio with biblionumber=%s does not have title defined",
              $biblio->biblionumber;
        }
        push @messages,
          sprintf "Edit these bibliographic records to define a title";
    }
    if ( !@messages ) { @messages = "All items have a title" }
    return @messages;
}

sub check_age_for_category {
    my @messages;
    my $aging_patrons = Koha::Patrons->search(
        {
            -not => {
                -or => {
                    'me.dateofbirth' => undef,
                    -and             => {
                        'categorycode.dateofbirthrequired' => undef,
                        'categorycode.upperagelimit'       => undef,
                    }
                }
            }
        },
        { prefetch => ['categorycode'] },
        { order_by => [ 'me.categorycode', 'me.borrowernumber' ] },
    );
    my @invalid_patrons;
    while ( my $aging_patron = $aging_patrons->next ) {
        push @invalid_patrons, $aging_patron
          unless $aging_patron->is_expired || $aging_patron->is_valid_age;
    }
    if (@invalid_patrons) {
        push @messages, "Patrons with invalid age for category";
        foreach my $invalid_patron (@invalid_patrons) {
            my $category = $invalid_patron->category;
            push @messages,
              sprintf
"Patron borrowernumber=%s has an invalid age of %s for their category '%s' (%s to %s)",
              $invalid_patron->borrowernumber, $invalid_patron->get_age,
              $category->categorycode,
              $category->dateofbirthrequired // '0',
              $category->upperagelimit       // 'unlimited';
        }
        push @messages,
"You may change the patron's category automatically with misc/cronjobs/update_patrons_category.pl";
    }
    if ( !@messages ) { @messages = "All patrons have valid age category" }
    return @messages;
}
