
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
        $Init->getIO->debug("i got a packet ".join(" ",@Info),__PACKAGE__);
        foreach my $data(@Info){
            $Init->getIO->debug_dumper($data);
        #$Init->getIO->debug("$data");
        }

    }

}
1;


