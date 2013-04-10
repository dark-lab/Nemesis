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
		    $self->command($po,lc($L));
   		    $self->command($spo,lc($PT));
		}

		method command($Packet,$Type){

			$self->match("event_".$Type,$Packet);

		}

		method match(@Args){
			my $Command=shift(@Args);
			foreach my $Module($self->Init->getModuleLoader->canModule($Command)){	
		    	my $Instance=$self->Init->getModuleLoader->getInstance($Module);
		    	$self->Init->getIO()->print_info("I can do that $Instance");
		    	eval { $Instance->$Command(@Args); };
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