
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
        is => 'rw',
        isa=>'Resources::Monitor'
    );

    method start() {

      if(!$self->Init->checkroot()){
        $self->Init->getIO()->print_alert("You need root permission to do this; otherwise you wouldn't see anything");
      }
      my $Sniffer=$self->Init->getModuleLoader()->loadmodule("Monitor");
       $Sniffer->start();
       $self->Sniffer($Sniffer);
    }


    method stop(){
        $self->Sniffer()->stop();
    }

}
1;


