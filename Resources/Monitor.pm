use MooseX::Declare;

use Nemesis::Inject;
class Resources::Monitor{
use Resources::Dispatcher;
	
use Net::Pcap::Easy;

	has 'Device' => (is=>"rw",default=>"mon0");
	has 'Filter' => (is=>"rw",default=>"");
	has 'Promiscuous' => (is=>"rw",default=>"0");
	has 'Dispatcher' => (is=>"rw");
	nemesis_resource;



	method run(){
		my $d=$self->Init->getModuleLoader->loadmodule("Dispatcher");
		$self->Dispatcher($d);
		$self->Init->getIO()->print_info("Listening on ".$self->Device. " with ".$self->Filter." Promisc:".$self->Promiscuous);
		my $npe = Net::Pcap::Easy->new(
										    dev              => $self->Device,
										    filter           => $self->Filter,
										    packets_per_loop => 10,
										    bytes_to_capture => 1024,
										    timeout_in_ms    => 0, # 0ms means forever
										    promiscuous      => $self->Promiscuous, # true or false
											default_callback => sub {
												$d->dispatch(@_);
											}
											
										);


		1 while $npe->loop;

		$self->Init->getIO()->print_alert("Exited from loop, something happened");
	}

}