package Koha::Plugin::SendEmails;

use Modern::Perl;
use strict;
use CGI;
use utf8;
use JSON::PP;
use Encode;
use base qw(Koha::Plugins::Base);
use C4::Auth;
use C4::Context;
use Koha::Patron;
use Koha::Account;
use Data::Dumper;
use Try::Tiny;
use Koha::Email;
use Cwd;

our $VERSION = 1;
our $metadata = {
	name            => 'SendEmails',
	author          => 'Olivier Vezina',
	description     => 'Send Emails',
	date_authored   => '2024-10-03',
	date_updated    => '2024-10-17',
	minimum_version => '23.05',
	maximum_version => undef,
	version         => $VERSION,
};



our $dbh = C4::Context->dbh();

my $emailConfirmMessagePass = "";
my $emailConfirmMessageFailed = "";

my $input=CGI->new;

sub new {
	my ( $class, $args ) = @_;
	$args->{metadata} = $metadata;
	$args->{metadata}->{class} = $class;
	my $self = $class->SUPER::new($args);

	return $self;
}


sub tmpl {
	my $self = shift;
	my $cgi = $self->{cgi};
	my $preferedLanguage = $cgi->cookie('KohaOpacLanguage');

    my $template = undef;
	eval {$template = $self->get_template( { file => "sendEmail" . $preferedLanguage . ".tt" } )};
	if( !$template ){
		$preferedLanguage = substr $preferedLanguage, 0, 2;
		eval {$template = $self->get_template( { file => "sendEmail_$preferedLanguage.tt" } )};
	}
	$template = $self->get_template( { file => 'sendEmail.tt' } ) unless $template;

	return $template
}

sub tool {
    my ( $self, $args ) = @_;
	my $cgi = $self->{cgi};
    my $template = $self->tmpl;

    my $entry = "SELECT code, title, content FROM letter WHERE code = 'EMAILSEND_TEST';";

    my $sth = $dbh->prepare($entry);

    $sth->execute();

    my @options = ( );
    my @count = ( );
    my @titles = ( );
    my @contents = ( );

    while(my @retreived_items = $sth->fetchrow_array()){
        push(@options, $retreived_items[0]);
        push(@titles, $retreived_items[1]);
        push(@contents, $retreived_items[2]);
        push(@count, $retreived_items[3]);
    }

    if(scalar @count ne "3"){
        $dbh->do("INSERT INTO letter 
            (module, code, name, title, content, lang)
            VALUES
            ('members', 'EMAILSEND_TEST', 'test_email', 'Courriel de test', 'Ceci est un test, vous pouvez l''ignorer', 'fr-CA'),
            ('members', 'EMAILSEND_TEST', 'test_email', 'Test Email', 'This is a test, please ignore it', 'en'),
            ('members', 'EMAILSEND_TEST', 'test_email', 'Test Email', 'This is a test, please ignore it', 'default');
        ");
    }

    my $title = undef;
    my $content = undef;

    my $number = $cgi->param('borrowerNumber');
	my $preferedLanguage = $cgi->cookie('KohaOpacLanguage');
    if($preferedLanguage eq "fr" || $preferedLanguage eq "fr-CA"){
        $title =  $titles[0];
        $content = $contents[0];
        $emailConfirmMessagePass = "Le courriel a été envoyé !";
        $emailConfirmMessageFailed = "Un problème a été rencontré.";
    }elsif($preferedLanguage eq "en"){
        $title =  $titles[1];
        $content = $contents[1];
        $emailConfirmMessagePass = "The email was successfully sent!";
        $emailConfirmMessageFailed = "The email failed to be sent.";
    }else{
        $title =  $titles[2];
        $content = $contents[2];
        $emailConfirmMessagePass = "The email was successfully sent!";
        $emailConfirmMessageFailed = "The email failed to be sent.";
    }

    if ($cgi->param('function') eq 'sendEmail'){
        $self->sendEmail($number, $title, undef, $content);
    }
    elsif($cgi->param('action') eq 'SendEmail'){
        $self->sendEmail(
            undef,
            $cgi->param('Subject'),
            $cgi->param('To'),
            $cgi->param('Body'),

        );
    }
    else{
        $self->home();
    }
}


sub home {
	my $self = shift;
	my $cgi = $self->{cgi};
	my $template = $self->tmpl;

	print $cgi->header(-type => 'text/html',-charset => 'utf-8');
	print $template->output();
}

sub intranet_js {
    my ( $self ) = @_;

    return qq|
        <script>
            const base = document.getElementById('sendwelcome');
            const parent = base.parentNode;
            const grandParent = parent.parentNode;
            const patronNumber = borrowernumber;
            let message = '';
            const div = document.getElementsByTagName('main');
            const url = new URL(window.location.href);
            const params = url.searchParams;
            let emailConfirmation = params.get('sentEmailMessage');

            const divMessage = document.createElement('div');
            const divMessage2 = document.createElement('div');
            divMessage.appendChild(divMessage2);
            if(!emailConfirmation){
                emailConfirmation = "";
            }
            else{
                divMessage.style.display = "flex";
                divMessage.style.width = "100%";
                divMessage.style.justifyContent = "center";
                divMessage2.classList.add("dialog");
                divMessage2.classList.add("message");
                divMessage2.style.display = "flex";
                divMessage2.style.width = "30%";
                divMessage2.style.justifyContent = "center";
                divMessage2.style.minWidth= "fit-content";
            }
            const node2 = document.createTextNode(emailConfirmation);
            divMessage2.appendChild(node2);
            const children = div[0].children;
            children[1].after(divMessage);

            if (document.documentElement.lang === 'fr') {
                message = 'Envoyer un courriel de test';
            } else if (document.documentElement.lang === 'fr-CA') {
                message = 'Envoyer un courriel de test';
            }
            else{
                message = 'Send test email';
            }
 
            const li = document.createElement('li');
            const a = document.createElement('a');
            const node = document.createTextNode(message);
            a.appendChild(node);
            a.href = "/cgi-bin/koha/plugins/run.pl?class=Koha%3A%3APlugin%3A%3ASendEmails&method=tool&function=sendEmail&borrowerNumber=" + patronNumber;
            li.appendChild(a);
            grandParent.appendChild(li);
        </script>
    |;
}

sub sendEmail() {
    my $self = shift;
    my $number = shift;
    my $subject = shift;
    my $to = shift;
    my $body = shift;
	my $cgi = $self->{cgi};
    my $template = $self->tmpl;

    my $patron = undef;
    my $library = undef;
    my $emailaddr = undef;
    if($number ne undef){
        $patron = Koha::Patrons->find( $number );
    }

    if($patron){
        $emailaddr = $patron->notice_email_address;
        $library = $patron->library; 
    }
    else{
        $emailaddr = $to;
    }

    my $email = Koha::Email->create(
        {
            text_body => $body,
            subject => $subject,
            from => C4::Context->preference('KohaAdminEmailAddress'),
            to => $emailaddr,
        }
    );

    my $smtp_server;
    if ( $library ) {
        $smtp_server = $library->smtp_server;
    }
    else {
        $smtp_server = Koha::SMTP::Servers->get_default;
    }

    my $smtp_transports->{ $smtp_server->id // 'default' } ||= $smtp_server->transport;
    my $smtp_transport = $smtp_transports->{ $smtp_server->id // 'default' };
    my $confirmation = undef;
    try {
        $email->send_or_die({ transport => $smtp_transport });
        $confirmation = 1;
        $template->param(
            confirmation => 1
        );
    }
    catch {
        $confirmation = 0;
        $template->param(
            confirmation => 0
        );
    };
    my $json = Encode::encode_utf8(qq({
        "pass": "$emailConfirmMessagePass",
        "failed": "$emailConfirmMessageFailed"
    }));
    my $data= JSON::PP::decode_json($json);
   if($number){
    if($confirmation){
        my $encoded =  Encode::encode_utf8  $data->{"pass"};
        print $input->redirect("/cgi-bin/koha/members/moremember.pl?borrowernumber=$number&sentEmailMessage=$encoded");
    }else{
        my $encoded =  Encode::encode_utf8  $data->{"failed"};
        print $input->redirect("/cgi-bin/koha/members/moremember.pl?borrowernumber=$number&sentEmailMessage=$encoded");
    }
   }
   else{
	    print $cgi->header(-type => 'text/html',-charset => 'utf-8');
    	print $template->output();
   }

}

#Supprimer le plugin avec toutes ses données
sub uninstall() {
    my ( $self, $args ) = @_;

    $dbh->do("DELETE FROM letter WHERE code = 'EMAILSEND_TEST';");
    return 1; # succès
}



