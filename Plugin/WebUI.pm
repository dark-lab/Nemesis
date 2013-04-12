package Plugin::WebUI;
use Moose;
use MooseX::Declare;
use Nemesis::Inject;

class Plugin::WebUI {
use Mojo::Server::Daemon;
  use Mojo::IOLoop;
    our $VERSION = '0.1a';
    our $AUTHOR  = "skullbocks & mudler";
    our $MODULE  = "Moose test module";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(info test run);

    nemesis_moosex_module;

    has 'Port' => (is=>"rw",default=>"8080");

    method test() {
        $self->Init->getIO()->print_info("test");
    }

    method run($ResourceName){

        eval ("use $ResourceName");
        $ResourceName->setInit($self->Init);

         my $daemon = Mojo::Server::Daemon->new(app => $ResourceName->app, listen => ['http://*:'.$self->Port ]);
         $daemon->start;
          Mojo::IOLoop->one_tick while 1;

    }





}

1;
