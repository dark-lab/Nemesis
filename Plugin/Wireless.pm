package Plugin::Wireless;
use Nemesis::BaseModule -base;

our $VERSION          = '0.1a';
our $AUTHOR           = "mudler";
our $MODULE           = "LiveSniffer plugin";
our $INFO             = "<www.dark-lab.net>";
our @PUBLIC_FUNCTIONS = qw(test wps);

sub wps {
    my $self   = shift;
    my $Target = $_[0];            #Mac address or essid
    my %Aps    = $self->Int->getAPs();

    if ( $Target =~ /\:/ ) {

        #$Init->io->info()

    }
    else {

        foreach my $interface ( keys %Aps ) {
            if($Aps{$interface}{"SSID"}=~/$Target/i){
                $self->Init->io->info("We have a match");
            }
        }
    }

}

sub auto_wps {

}

sub test {
    my $self   = shift;
    my $Reaver = $self->Init->ml->atom("Reaver");
    $Reaver->channel("test");
    $self->Init->io->debug( $Reaver->_generateCommand() );

}

1;
