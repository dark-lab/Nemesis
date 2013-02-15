package Plugin::WebUI;
use Moose;
use MooseX::Declare;
use Nemesis::Inject;

class Plugin::WebUI {

    our $VERSION = '0.1a';
    our $AUTHOR  = "skullbocks & mudler";
    our $MODULE  = "Moose test module";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test);

    nemesis_moosex_module;

    method test() {
        $self->Init->getIO()->print_info("test");
    }

}

1;
