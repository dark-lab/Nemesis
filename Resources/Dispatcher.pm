use MooseX::Declare;
use Nemesis::Inject;

class Resources::Dispatcher{

		nemesis_moosex_resource;

		method dispatch(@Packet_info){
		    my ($this,$npe, $ether, $po, $spo, $header ) = @_;
		    $self->debug($po);
			$self->debug($spo);
		    my ($L) = $po=~/\:\:(.*)\=/;
		    my ($PT) = $spo=~/\:\:(.*)\=/;
		    $L=lc($L);$PT=lc($PT);
		    $self->command($po,$L);
   		    $self->command($spo,$PT);
		}

		method command($Packet,$Type){

		    my $command="event_".$Type;
			foreach my $Module($self->Init->getModuleLoader->canModule($command)){	
		    	my $Instance=$self->Init->getModuleLoader->getInstance($Module);
		    	$self->Init->getIO()->print_info("I can do that $Instance $Packet $Type");
		    	eval { $Instance->$command($Packet); };
		    }

		}

		method debug($Packet){


		    if( $Packet ) {

   			 	my $IO = $self->Init->getIO;
		        if( $Packet->isa("NetPacket::IP") ) {
					$IO->print_info("IP packet: ".$Packet->{src_ip}." -> ".$Packet->{dest_ip});
		      	} elsif( $Packet->isa("NetPacket::TCP") ) {
					$IO->print_info("TCP packet: ".$Packet->{src_port}." -> ".$Packet->{dest_port});
	            } elsif( $Packet->isa("NetPacket::UDP") ) {
	            	$IO->print_info("UDP packet: ".$Packet->{src_port}." -> ".$Packet->{dest_port});
		        } elsif( $Packet->isa("NetPacket::ARP") ) {
	            	$IO->print_info("ARP packet: ".$Packet->{sha}." -> ".$Packet->{tha});
		        }
		        else {
   	   			 	$self->Init->getIO()->debug_dumper($Packet);
		        }
		    } 


		}

}