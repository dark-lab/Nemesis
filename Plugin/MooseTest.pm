package Plugin::MooseTest;


#use Moose;
use MooseX::DeclareX
    keywords => [qw(class)],
    plugins  => [qw(guard build preprocess std_constants)],
    types    => [ -Moose ];
use Nemesis::Inject;

class Plugin::MooseTest {

    our $VERSION = '0.f1a';
    our $AUTHOR  = "f";
    our $MODULE  = "Tf";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test );

    nemesis_moosex_module;

        has 'Process' => (
            is => 'rw',
        );
    method test() {
            my $Process=$self->Init->getModuleLoader->loadmodule("Process");
            $Process->set(
                type=> "thread",
                module=>"Run"
                );
            $Process->start();
            $self->Process($Process);
    }

    method clear(){
        $self->Process()->destroy();
    }

}

1;


