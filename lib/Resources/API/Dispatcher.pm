package Resources::API::Dispatcher;
use Nemesis::BaseRes -base;


sub dispatch_packet() {
    my $self  = shift;
    my $Frame = shift;

    #$Init->io->info($Frame->print);
    #print "LAyer: ".join(",",$oSimple->layers)."\n";

    # my $this=shift @Packet_info;
    #my $npe=shift @Packet_info;
    # $self->debug($po);
    #$Init->io->debug("my Frame is ".$Frame);
    foreach my $data ( $Frame->layers ) {
        my ($Type) = $data =~ /.*\:\:(.*?)\=/;

        #$Init->io->debug("$data");
        if ( defined($Type) ) {

            #$Init->getIO->debug("$data is $Type");
            $self->match( "event_" . lc($Type), $Frame );

            #$self->debug($data);
        }
    }
}

sub job() {
    my $self    = shift;
    my $event   = shift;
    my $object  = shift;
    my $Process = $self->Init->ml->loadmodule("Process");
    $Process->set(
        type => "thread",
        code => sub {

            # threads->detach;
            #      $self->match($event,$object);
            # threads->exit;
            $self->Init->io->debug("ok");
            }

    );
    $Process->start;

    #  $Process->detach;
    $Process->join();

    #$self->Process($Process);

}

sub match($@) {
    my $self    = shift;
    my @Args    = @_;
    my $Command = shift(@Args);
    if ( $Command =~ /\:\:/ ) {
        $Command =~ s/\:\:/\_\_/g;
    }
    $self->Init->io->debug("Searching $Command");
    foreach my $Module ( $self->Init->getModuleLoader->canModule($Command) ) {
        my $Instance = $self->Init->getModuleLoader->getInstance($Module);

        $self->Init->getIO()->print_info("I can do that $Instance");
        eval { $Instance->$Command(@Args); };
    }
}
1;

