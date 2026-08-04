package Koha::Plugin::OpacTheme;
use Modern::Perl;
use base qw(Koha::Plugins::Base);
use C4::Context;
use URI::Escape;
use JSON;
use Koha::Plugins;
use C4::Languages;
use File::Slurp;
use File::Basename;
use Cwd 'abs_path';
# use feature 'switch'

our $VERSION = '0.9';
our $metadata = {
    name   => 'OpacTheme',
    author => 'Ludovic Julien',
    description => 'Add seasonal themes to the OPAC.',
    date_authored => '2025-09-09',
    date_updated    => '2025-09-15',
    version => $VERSION,
    minimum_version => '24.05',
};

sub new {
    my ($class, $args) = @_;
    $args->{metadata} = $metadata;
    return $class->SUPER::new($args);
}

sub api_namespace {
    my ( $self ) = @_;
    return 'OpacTheme-api';
}

sub static_routes {
    my $self = shift;
    my $spec_str = $self->mbf_read('api/staticapi.json');
    my $spec = decode_json($spec_str);
    return $spec;
}

#envoie le css a l'OPAC (en inline pour éviter le temps de chargement long)
sub opac_head {
    my ($self) = @_;

    my $theme = $self->retrieve_data("selected_theme") // 'noel';

    my $plugin_pm_path = abs_path(__FILE__);
    my $plugin_dir = dirname($plugin_pm_path);


    my $css_path = "$plugin_dir/OpacTheme/css/$theme.css";

    if (-e $css_path) {
        my $css_content = read_file($css_path, binmode => ':utf8'); #obligatoire pour lire l'emoji 
        return qq{
            <style id="theme-inline-css">
            $css_content
            </style>
        };
    } else {
        warn "❌ CSS file not found at path: $css_path";
        return '';
    }
}

#envoie le js a l'OPAC
sub opac_js {
    my ($self) = @_;
    my $api_ns = $self->api_namespace;

    my $theme = $self->retrieve_data("selected_theme") // 'noel';
    return "" if $theme eq 'null';

    my $script_options = "";

    if ($theme eq 'noel') {
        my $activation_flocons = $self->retrieve_data("activation_flocons") // 'on';
        my $vitesse = $self->retrieve_data("vitesse_flocons") // 'normal';
        my $taille  = $self->retrieve_data("taille_flocons")  // 'normal';
        my $vent    = $self->retrieve_data("vent_flocons")    // 'null';
        my $quantite = $self->retrieve_data("quantite_flocons") // '50';

        $script_options = qq{
            <script>
                window.NoelThemeOptions = {
                    activation_flocons: "$activation_flocons",
                    vitesse: "$vitesse",
                    taille: "$taille",
                    vent: "$vent",
                    quantite_flocons: "$quantite"
                };
            </script>
        };
    }
    elsif ($theme eq 'saint-valentin') {
        my $activation_coeurs = $self->retrieve_data("activation_coeurs") // 'on';
        my $vitesse = $self->retrieve_data("vitesse_coeurs") // 'normal';
        my $taille  = $self->retrieve_data("taille_coeurs")  // 'normal';
        my $vent    = $self->retrieve_data("vent_coeurs")    // 'null';
        my $quantite = $self->retrieve_data("quantite_coeurs") // '50';

        $script_options = qq{
            <script>
                window.StValentinThemeOptions = {
                    activation_coeurs: "$activation_coeurs",
                    vitesse: "$vitesse",
                    taille: "$taille",
                    vent: "$vent",
                    quantite_coeurs: "$quantite"
                };
            </script>
        };
    }
    elsif ($theme eq 'halloween') {
        my $activation_spiders = $self->retrieve_data("activation_spiders") // 'on';
        my $quantite_spiders = $self->retrieve_data("quantite_spiders") // '2';
        my $activation_ghost = $self->retrieve_data("activation_ghost") // 'on';

        $script_options = qq{
            <script>
                window.HalloweenThemeOptions = {
                    activation_spiders: "$activation_spiders",
                    quantite_spiders: "$quantite_spiders",
                    activation_ghost: "$activation_ghost"
                };
            </script>
        };
    }
    elsif ($theme eq 'paque') {
        my $activation_eggs = $self->retrieve_data("activation_eggs") // 'on';

        $script_options = qq{
            <script>
                window.PaqueThemeOptions = {
                    activation_eggs: "$activation_eggs"
                };
            </script>
        };
    }
    else {
        # pas de configuration spécifique
    }

    return qq{
        $script_options
        <script id="theme-js" src="/api/v1/contrib/$api_ns/static/js/$theme.js"></script>
    };
}



# Enregistre les sélections de theme dans la BD
sub apply_theme {
    my ($self) = @_; 
    my $cgi = $self->{cgi};  

    my $theme = $cgi->param('theme');
    my %data = ( selected_theme => $theme );

    if ($theme eq 'noel') {
        $data{activation_flocons} = $cgi->param('activation_flocons') // 'on';
        $data{vitesse_flocons}    = $cgi->param('vitesse_flocons') // 'normal';
        $data{taille_flocons}     = $cgi->param('taille_flocons') // 'normal';
        $data{vent_flocons}       = $cgi->param('vent_flocons') // 'null';
        $data{quantite_flocons}   = $cgi->param('quantite_flocons') // '50';
    }
    elsif ($theme eq 'saint-valentin') {
        $data{activation_coeurs} = $cgi->param('activation_coeurs') // 'on';
        $data{vitesse_coeurs}    = $cgi->param('vitesse_coeurs') // 'normal';
        $data{taille_coeurs}     = $cgi->param('taille_coeurs') // 'normal';
        $data{vent_coeurs}       = $cgi->param('vent_coeurs') // 'null';
        $data{quantite_coeurs}   = $cgi->param('quantite_coeurs') // '50';
    }
    elsif ($theme eq 'halloween') {
        $data{activation_spiders} = $cgi->param('activation_spiders') // 'on';
        $data{quantite_spiders}   = $cgi->param('quantite_spiders') // '2';
        $data{activation_ghost}   = $cgi->param('activation_ghost') // 'on';
    }
    elsif ($theme eq 'paque') {
        $data{activation_eggs} = $cgi->param('activation_eggs') // 'on';
    }

    $self->store_data(\%data, { flatten => 0 });

    print $cgi->header('application/json');
    print to_json({ success => JSON::true, theme => $theme });
}


#Sélectionne le bon template de config celon la langue de l'utilisateur
sub retrieve_template {
    my ( $self, $template_prefix ) = @_;
    my $cgi = $self->{cgi};

    my $template;
    my $preferredLanguage = C4::Languages::getlanguage();

    if ($preferredLanguage) {
        eval {
            $template = $self->get_template({ file => $template_prefix . '_' . $preferredLanguage . '.tt' });
        };
        if (!$template) {
            $preferredLanguage = substr($preferredLanguage, 0, 2);
            eval {
                $template = $self->get_template({ file => $template_prefix . '_' . $preferredLanguage . '.tt' });
            };
        }
    }
    $template = $self->get_template({ file => $template_prefix . '.tt' }) unless $template;

    return $template;
}

# gère l'interface de l'intranet
sub tool {
    my ($self, $args) = @_;
    my $cgi = $self->{cgi};

    my $koha_session = $cgi->cookie('KohaSession') // $cgi->param('koha_session');

    my $template = $self->retrieve_template('homeTheme');

    $template->param(
        enabled => 1,
        CLASS   => ref $self,
        METHOD  => 'tool',
        api_namespace  => $self->api_namespace,
        koha_session => $koha_session, 
        selected_theme => $self->retrieve_data("selected_theme") // 'null',

        activation_flocons => $self->retrieve_data("activation_flocons") // 'on',
        neige_vitesse  => $self->retrieve_data("neige_vitesse") // 'normal',
        taille_flocons => $self->retrieve_data("taille_flocons") // 'normal',
        vent_flocons   => $self->retrieve_data("vent_flocons") // 'null',
        quantite_flocons   => $self->retrieve_data("quantite_flocons") // '50',

        activation_coeurs => $self->retrieve_data("activation_coeurs") // 'on',
        vitesse_coeurs  => $self->retrieve_data("vitesse_coeurs") // 'normal',
        taille_coeurs => $self->retrieve_data("taille_coeurs") // 'normal',
        vent_coeurs   => $self->retrieve_data("vent_coeurs") // 'null',
        quantite_coeurs   => $self->retrieve_data("quantite_coeurs") // '50',
    );

    print $cgi->header(-type => 'text/html', -charset => 'utf-8');
    print $template->output();
}



sub uninstall {
    my ( $self, $args ) = @_;
    my $dbh = C4::Context->dbh;
    my $sth_select = $dbh->prepare("SELECT * FROM systempreferences WHERE variable = 'OpacMainUserBlock'");
    $sth_select->execute();

    my $value;
    if (my $row = $sth_select->fetchrow_hashref) {
        $value = "$row->{'value'}";
    }

    my $start_tag = "<!-- Debut plugin noel -->";
    my $end_tag   = "<!-- Fin plugin noel -->";

    # if ($value && $value =~ /$start_tag.*?$end_tag/s) {
        $value =~ s/$start_tag.*?$end_tag//s;

        my $sth_update = $dbh->prepare("UPDATE systempreferences SET value = ? WHERE variable = 'OpacMainUserBlock'");
        $sth_update->bind_param(1, $value);
        $sth_update->execute;
        $sth_update->finish;
    # }

    # my $sth_delete = $dbh->prepare("DELETE FROM plugin_data WHERE plugin_class = ?");
    # $sth_delete->execute($self->class());
    # $sth_delete->finish;

    $sth_select->finish;

    return 1;
}



1;
