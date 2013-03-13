use MooseX::Declare;
class Resources::Dispatcher{
	use Nemesis::Inject;
		nemesis_moosex_resource;
		method dispatch(@Packet_info){
		    my ($npe, $ether, $po, $spo, $header ) = @_;
		    if( $po ) {
   			 	$self->Init->debug_dumper($spo);

		        if( $po->isa("NetPacket::IP") ) {


		            if( $spo ) {
		                if( $spo->isa("NetPacket::TCP") ) {
		                    print "TCP packet: $po->{src_ip}:$spo->{src_port} -> ",
		                        "$po->{dest_ip}:$spo->{dest_port}\n";
		 
		                } elsif( $spo->isa("NetPacket::UDP") ) {
		                    print "UDP packet: $po->{src_ip}:$spo->{src_port} -> ",
		                        "$po->{dest_ip}:$spo->{dest_port}\n";
		 
		                } else {
		                    print "", ref($spo), ": $po->{src_ip} -> ",
		                        "$po->{dest_ip} ($po->{type})\n";
		                }
		 
		            } else {
		                print "IP packet: $po->{src_ip} -> $po->{dest_ip}\n";
		            }
		 
		        } elsif( $po->isa("NetPacket::ARP") ) {
		            print "ARP packet: $po->{sha} -> $po->{tha}\n";
		        }
		 
		    } else {
		        print "IPv6 or appletalk or something... huh\n";
		    }
		}


}