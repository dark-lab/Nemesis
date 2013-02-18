package Plugin::MooseTest;


use MooseX::Declare;

use Nemesis::Inject;
  use namespace::autoclean;
class Plugin::MooseTest {

    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "Moose testing plugin";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test );

    nemesis_moosex_module;

    has 'Process' => (
        is => 'rw',
    );

    method test() {
        #$self->Init->getIO()->print_info($self->Init->getModuleLoader->_findLibName("http://dark-lab.net/Speech.pm"));
        #$self->Init->getModuleLoader->loadmodule("http://dark-lab.net/Process.pm");
             my $Process=$self->Init->getModuleLoader->loadmodule("Process");
            $Process->set(
                type=> "thread",
                module=>"Run"
                );
            $Process->start();
            $self->Process($Process);
    }

    method clear(){
        $self->Process()->destroy() if($self->Process);
    }

}
  __PACKAGE__->meta->make_immutable;
1;


