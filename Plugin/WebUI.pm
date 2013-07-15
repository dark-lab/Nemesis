package Plugin::WebUI;
use Moose;
use Mojo::Server::Daemon;
use Mojo::IOLoop;
use Nemesis::Inject;

our $VERSION = '0.1a';
our $AUTHOR  = "skullbocks & mudler";
our $MODULE  = "Moose test module";
our $INFO    = "<www.dark-lab.net>";

our @PUBLIC_FUNCTIONS = qw(test run);

nemesis module {}

    has 'Port' => ( is => "rw", default => "8080" );

sub test() {
    my $self = shift;
    $self->Init->getIO()->print_info("test");
}

sub run() {
    my $self         = shift;
    my $ResourceName = shift;
    eval("use $ResourceName");
    $ResourceName->setInit($Init);

    my $daemon = Mojo::Server::Daemon->new(
        app    => $ResourceName->app,
        listen => [ 'http://*:' . $self->Port ]
    );
    $daemon->start;
    Mojo::IOLoop->one_tick while 1;

}

1;
