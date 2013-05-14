use MooseX::Declare;
use Nemesis::Inject;

class Resources::Dispatcher{

		nemesis_resource;

		method dispatch_packet($Frame){

		    #$Init->io->info($Frame->print);
     	  #print "LAyer: ".join(",",$oSimple->layers)."\n";

   
		   # my $this=shift @Packet_info;
		    #my $npe=shift @Packet_info;
		   # $self->debug($po);
			#$Init->io->debug("my Frame is ".$Frame);
			foreach my $data($Frame->layers){
			my ($Type) = $data=~/.*\:\:(.*?)\=/;
			#$Init->io->debug("$data");
				if(defined($Type)){
					#$Init->getIO->debug("$data is $Type");
					$self->match("event_".lc($Type),$Frame);
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