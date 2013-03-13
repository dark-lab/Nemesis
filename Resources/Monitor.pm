use MooseX::Declare;

class Resources::Monitor{

	
use Net::Pcap::Easy;

	has 'Device' => (is=>"rw",default=>"wlp3s0");
	has 'Filter' => (is=>"rw",default=>"host 127.0.0.1 and (tcp or icmp)");
	has 'Promiscuous' => (is=>"rw",default=>"1");
	has 'Process' => (is=>"rw",isa=>"Nemesis::Process");

	method start(){

		my $Process=$self->Init->getModuleLoader()->loadmodule("Process");
		my $Dispatcher=$self->Init->getModuleLoader()->loadmodule("Dispatcher"); #The difference is that here you have Init injected.
		$Process->set(
			type=>"thread"
			code=> sub {
						my $npe = Net::Pcap::Easy->new(
							    dev              => $self->Device,
							    filter           => $self->Filter,
							    packets_per_loop => 10,
							    bytes_to_capture => 1024,
							    timeout_in_ms    => 0, # 0ms means forever
							    promiscuous      => $self->Promiscuous, # true or false
								default_callback => sub {
									$Dispatcher->dispatch(@_);
								}					 
							);
						}
			);
		$Process->start();
		$self->Process($Process);

	}
	method stop(){
		$self->Process->destroy();
	}
}