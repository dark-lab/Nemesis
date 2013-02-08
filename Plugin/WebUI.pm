package Plugin::WebUI;
use Moose;
use MooseX::DeclareX
    keywords => [qw(class)],
    plugins  => [qw(guard build preprocess std_constants)],
    types    => [ -Moose ];
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
