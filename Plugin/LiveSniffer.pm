
use MooseX::Declare;

use Nemesis::Inject;

class Plugin::LiveSniffer {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "LiveSniffer plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info start stop);

    nemesis_moosex_module;

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

}
1;


