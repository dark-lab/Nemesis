
use MooseX::Declare;

use Nemesis::Inject;

class Plugin::LiveSniffer {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "LiveSniffer plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(start stop);
use Net::Packet;
    nemesis_module;

    has 'Sniffer' => (
        is => 'rw'
    );

    method start() {

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

    method clear(){
      $self->stop();
    }

    method stop(){
        $self->Sniffer()->destroy() if($self->Sniffer);
    }

    method event_tcp($Frame){
        $Init->io->info($Frame->print);
        my $Tcp=$Frame->ref->{'TCP'}->unpack;
        my $payload= $Tcp->payload if $Tcp;
        $Init->io->debug('PAYLOAD: '.$payload) if $Tcp->payload;
    }

    method event_udp($Frame){
        #$Init->io->info($Frame->print);

    }

    method event_arp($Frame){
        #$Init->io->info($Frame->print);
    }

 
}
1;


