package Plugin::LiveSniffer;

use Moose;
use Nemesis::Inject;
use Net::Packet;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "LiveSniffer plugin";
our $INFO    = "<www.dark-lab.net>";
our @PUBLIC_FUNCTIONS = qw(start stop);

nemesis_module;

    has 'Sniffer' => (
        is => 'rw'
    );

    sub start() {
        my $self=shift;

      if($Init->checkroot()){
        $Init->io()->print_alert("You need root permission to do this; otherwise you wouldn't see anything");
      }
          my $Process=$self->Init->getModuleLoader->loadmodule("Process");

     my $Monitor=$self->Init->getModuleLoader->loadmodule("Monitor");
                $Monitor->Device("wlan0");
                $Process->set(
                        type=> "thread",
                        instance=>$Monitor
                        );
                $Process->start();


            # my @Devs=$Init->interfaces->connected_devices;
            # foreach my $dev(@Devs){
            #     next if ($dev=~/mon/i or $dev=~/lo/i);
            #     $Init->io->info("Starting sniff on $dev");
            #     my $Monitor=$self->Init->getModuleLoader->loadmodule("Monitor");
            #     $Monitor->Device($dev);
            #     $Process->set(
            #             type=> "thread",
            #             instance=>$Monitor
            #             );
            #     $Process->start();
            # }
           
            $self->Sniffer($Process);
    }

    sub clear(){
        my $self=shift;
      $self->stop();
    }

    sub stop(){
        my $self=shift;
        $self->Sniffer()->destroy() if($self->Sniffer);
    }

    sub event_tcp(){
                my $self=shift;
                my $Frame=shift;

        $Init->io->info($Frame->print);
        my $Tcp=$Frame->ref->{'TCP'}->unpack;
        my $payload= $Tcp->payload if $Tcp;
        $Init->io->debug('PAYLOAD: '.$payload) if $Tcp->payload;
    }
 

1;