
use MooseX::Declare;

use Nemesis::Inject;

class Plugin::LiveSniffer {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "LiveSniffer plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(start stop);

    nemesis_module;

    has 'Sniffer' => (
        is => 'rw'
    );

    method start() {

      if($self->Init->checkroot()){
        $self->Init->getIO()->print_alert("You need root permission to do this; otherwise you wouldn't see anything");
      }
          my $Process=$self->Init->getModuleLoader->loadmodule("Process");
          my $Monitor=$self->Init->getModuleLoader->loadmodule("Monitor");

            $Process->set(
                type=> "thread",
                instance=>$Monitor
                );
            $Process->start();
            $self->Sniffer($Process);
    }

    method clear(){
      $self->stop();
    }

    method stop(){
        $self->Sniffer()->destroy() if($self->Sniffer);
    }

    method event_tcp(@Info){
        $Init->io->info(__PACKAGE__." Received a TCP package");
        foreach my $data(@Info){
            $self->debug($data);
        }
    }

    method event_arp(@Info){
         $Init->io->info(__PACKAGE__." Received an ARP package");
        foreach my $data(@Info){
            $self->debug($data);
        }
    }

    method debug($Packet){
            if( $Packet ) {
                my $IO = $Init->io;
               # $Init->io->debug("Packet is $Packet");
                if( $Packet->isa("NetPacket::IP") ) {
                    $IO->tabbed("IP packet: ".$Packet->{src_ip}." -> ".$Packet->{dest_ip});
                } elsif( $Packet->isa("NetPacket::TCP") ) {
                    $IO->tabbed("TCP packet: ".$Packet->{src_port}." -> ".$Packet->{dest_port});
                } elsif( $Packet->isa("NetPacket::UDP") ) {
                    $IO->tabbed("UDP packet: ".$Packet->{src_port}." -> ".$Packet->{dest_port});
                } elsif( $Packet->isa("NetPacket::ARP") ) {
                    $IO->tabbed("ARP packet: ".$Packet->{sha}." -> ".$Packet->{tha});
                }
                else {
                  #  $self->Init->io()->debug_dumper(\$Packet);
                }
            } 
        }

}
1;


