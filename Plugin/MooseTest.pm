package Plugin::MooseTest;


use MooseX::Declare;

use Nemesis::Inject;
  use namespace::autoclean;
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
  __PACKAGE__->meta->make_immutable;
1;


