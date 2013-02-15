package Plugin::metasploit;
use warnings;
use Carp qw( croak );
use Nemesis::Inject;
require Data::MessagePack;
require LWP;
require HTTP::Request;
my $VERSION = '0.1a';
my $AUTHOR  = "mudler";
my $MODULE  = "Metasploit Module";
my $INFO    = "<www.dark-lab.net>";

#Public exported functions
my @PUBLIC_FUNCTIONS =
    qw(configure call check_installation status where stop status_pids browser_autopwn)
    ;    #NECESSARY
my $CONF = {
    VARS => {
        MSFRPCD_USER => 'spike',
        MSFRPCD_PASS => 'spiketest',
        MSFRPCD_PORT => 5553,
        HOST         => '127.0.0.1',
        MSFRPCD_API  => '/api/',
    }
};

#nemesis_module;
#TODO: Rendere il modulo esterno, creando un'altro oggetto Moose per l'interazione con msfrpcd
nemesis_module;

sub prepare {
    $Init->getIO()
        ->print_info( "Testing " . __PACKAGE__ . " prepare() function" )
        ;    #This is called after initialization of Init
}

sub call() {
    my $self        = shift;
    my $meth        = shift;
    my @opts        = @_;
    my $UserAgent   = LWP::UserAgent->new;
    my $MessagePack = Data::MessagePack->new();
    $self->start()
        if ( !exists( $self->{'process'}->{'msfrpcd'} ) );
    my $URL =
          'http://'
        . $CONF->{'VARS'}->{'HOST'} . ":"
        . $CONF->{'VARS'}->{'MSFRPCD_PORT'}
        . $CONF->{'VARS'}->{'MSFRPCD_API'};
    if ( $meth ne 'auth.login' and !$self->{_authenticated} ) {
        $self->msfrpc_login();
    }
    unshift @opts, $self->{_token} if ( exists( $self->{_token} ) );
    unshift @opts, $meth;
    my $HttpRequest = new HTTP::Request( 'POST', $URL );
    $HttpRequest->content_type('binary/message-pack');
    $HttpRequest->content( $MessagePack->pack( \@opts ) );
    my $res = $UserAgent->request($HttpRequest);
    $self->parse_result($res);
    croak( "MSFRPC: Could not connect to " . $URL )
        if $res->code == 500;
    croak("MSFRPC: Request failed ($meth)") if $res->code != 200;
    $Init->getIO()->debug_dumper( $MessagePack->unpack( $res->content ) );
    return $MessagePack->unpack( $res->content );
}

sub browser_autopwn() {
    my $self    = shift;
    my @OPTIONS = (
        "auxiliary",
        "server/browser_autopwn",
        {   LHOST   => "0.0.0.0",
            SRVPORT => "8080",
            URIPATH => "/"
        }
    );
    $response = $self->call( "module.execute", @OPTIONS );
    if ( exists( $response->{'uuid'} ) ) {
        $Init->getIO()
            ->print_alert(
            "Now you have to wait until browser_autopwn finishes loading exploits."
            );
        $self->parse_result($response);
        $Init->getIO()->print_tabbed( "Your URL : http://0.0.0.0:8080", 2 );
    }
    else {
        $Init->getIO()->print_error("Something went wrong");
    }
}

sub msfrpc_login() {
    my $self = shift;
    my $user = $CONF->{'VARS'}->{'MSFRPCD_USER'};
    my $pass = $CONF->{'VARS'}->{'MSFRPCD_PASS'};
    my $ret  = $self->call( 'auth.login', $user, $pass );
    if ( $ret->{'result'} eq 'success' ) {
        $self->{_token}         = $ret->{'token'};
        $self->{_authenticated} = 1;
    }
    else {
        $Init->getIO()->debug_dumper($ret);
        $Init->getIO()->print_error("Failed auth with MSFRPC");
    }
}

sub help() {    #NECESSARY
    my $self    = shift;
    my $IO      = $self->{'core'}->{'IO'};
    my $section = $_[0];
    $IO->print_title( $MODULE . " Helper" );
    if ( $section eq "configure" ) {
        $IO->print_title("nothing to configure here");
    }
}

sub start {
    my $self  = shift;
    my $which = $_[0];
    my $Io    = $Init->getIO();
    my $code =
          'msfrpcd -U '
        . $CONF->{'VARS'}->{'MSFRPCD_USER'} . ' -P '
        . $CONF->{'VARS'}->{'MSFRPCD_PASS'} . ' -p '
        . $CONF->{'VARS'}->{'MSFRPCD_PORT'} . ' -S';
    $Io->print_info("Starting msfrpcd service.");
    my $Process = $Init->getModuleLoader->loadmodule('Process');
    $Process->set(
        type => 'daemon',    # forked pipeline
        code => $code,
        Init => $Init,
    );
    $Process->start();
    $Io->debug( $Io->generate_command($code) );
    $self->{'process'}->{'msfrpcd'} = $Process;
    if ( $Process->is_running ) {
        $Io->print_info("Service msfrcpd started");
        $Io->process_status($Process);
        $Io->print_alert(
            "Now you have to give some time to metasploit to be up and running.."
        );
    }
}

sub clear() {
    my $self = shift;
    if ( exists( $self->{'process'}->{'msfrpcd'} ) ) {
        $self->{'process'}->{'msfrpcd'}->destroy();
        delete $self->{'process'}->{'msfrpcd'};
    }
    else {
        $Init->getIO()->print_alert("Process already stopped");
    }
}

sub status {
    my $self = shift;
    my $process;
    foreach my $service ( keys %{ $self->{'process'} } ) {
        $self->process_status($service);
    }
}

sub parse_result() {
    my $self = shift;
    my $pack = $_[0];
    if ( exists( $pack->{'error'} ) ) {
        $Init->getIO()
            ->print_error("Something went wrong with your MSFRPC call");
        $Init->getIO()->print_error( "Code error: " . $pack->{'error_code'} );
        $Init->getIO()->print_error( "Message: " . $pack->{'error_message'} );
        foreach my $trace ( $pack->{'error_backtrace'} ) {
            $Init->getIO()->print_tabbed( "Backtrace: " . $trace, 2 );
        }
    }
    else {
        if ( exists( $pack->{'job_id'} ) ) {
            $Init->getIO()->print_info( "Job ID: " . $pack->{'job_id'} );
        }
    }
}
1;
__END__
