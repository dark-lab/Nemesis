use MooseX::Declare;
use Nemesis::Inject;

class Resources::Dispatcher{

		nemesis_resource;

		method dispatch_packet(@Packet_info){
		    
		   # my $this=shift @Packet_info;
		    my $npe=shift @Packet_info;
		   # $self->debug($po);
			#$self->debug($spo);
			foreach my $data(@Packet_info){
				my ($Type) = $data=~/\:\:(.*)\=/;
				if(defined($Type)){
					#$Init->getIO->debug("$data is $Type");
					$self->match("event_".lc($Type),@Packet_info);
					#$self->debug($data);
				}
			}
		}

		method match(@Args){
			my $Command=shift(@Args);
			foreach my $Module($self->Init->getModuleLoader->canModule($Command)){	
		    	my $Instance=$self->Init->getModuleLoader->getInstance($Module);
		    	#$self->Init->getIO()->print_info("I can do that $Instance");
		    	eval { $Instance->$Command(@Args); };
		    }
		}


}