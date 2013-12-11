package Resources::API::MSFRPC;

use Nemesis::BaseRes -base;
use Data::MessagePack;
use LWP;
use HTTP::Request;
use Resources::Util;
#http://blog.spiderlabs.com/2012/01/scripting-metasploit-using-msgrpc-.html
has 'Username' => sub {'spike'};
has 'Password' => sub {'spiketest'};
has 'Host'     => sub {'127.0.0.1'};
has 'Port'     => sub {5553};
has 'API'      => sub {'/api/'};
has 'Token';
has 'Auth' => sub {0};
has 'Result';
has 'currentConsole';
has 'opened_consoles' => sub { [] };

sub call() {
    my $self    = shift;
    my @Options = @_;
    my $meth    = shift @Options;

    $self->Init->io->debug(
        "Options called to metasploit: " . join( ",", @Options ) );
    my $UserAgent   = LWP::UserAgent->new;
    my $MessagePack = Data::MessagePack->new();

    # $self->Init->getIO()->debug("Method $meth");
    my $URL = 'http://' . $self->Host . ":" . $self->Port . $self->API;
    if ( $meth ne 'auth.login' and $self->Auth != 1 ) {
        $self->login();
    }
    unshift @Options, $self->Token() if ( $self->Token() );
    unshift @Options, $meth;
    my $HttpRequest = new HTTP::Request( 'POST', $URL );
    $HttpRequest->content_type('binary/message-pack');
    $HttpRequest->content( $MessagePack->pack( \@Options ) );
    my $res = $UserAgent->request($HttpRequest);

    #$self->Init->getIO->debug_dumper($res);
    $self->error($res) and return if $res->code == 500 or $res->code != 200;

    $self->Result( $MessagePack->unpack( $res->content ) );
    $self->Init->io->error( $self->Result->{'error_message'} )
        and return $self->Result
        if defined $self->Result
        and exists $self->Result->{'error_message'}
        and $res->code == 200;

    #  $self->parse_result();
    $self->Init->getIO()->debug_dumper( $self->Result );
    return $self->Result;
}

sub create_console() {
    my $self     = shift;
    my $Response = $self->call('console.create');
    $self->Init->io->debug_dumper($Response);
    $self->Init->io->debug("Creating console");
    push( @{ $self->opened_consoles }, $Response->{'id'} )
        if exists $Response->{'id'};
    $self->select_console( $Response->{'id'} )
        if ( !defined $self->currentConsole );
    $self->Init->io->debug(
        "generated " . $self->currentConsole . " console" );
}

sub select_console() {
    my $self = shift;
    my $ID   = shift;
    if ( &Resources::Util::match( $self->opened_consoles, $ID ) ) {
        $self->currentConsole($ID);
        $self->Init->io->debug("Switched console to $ID");
    }
    else {
        $self->Init->io->error("No console in the list");
    }

}

sub load_console() {
    my $self     = shift;
    my $Response = $self->call('console.list');
    @{ $self->opened_consoles } = keys %{$Response}
        if $Response;

}

sub console_write() {
    my $self    = shift;
    my $command = shift;
    my $console = shift // $self->currentConsole;

    if ( &Resources::Util::match( $self->opened_consoles, $console ) ) {

        return $self->call( "console.write", $console, $command );
    }
    else {
        $self->Init->io->error("No console in the list");
    }

}

sub console_read() {
    my $self = shift;
    my $console = shift // $self->currentConsole;

    if ( &Resources::Util::match( $self->opened_consoles, $console ) ) {

        return $self->call( "console.read", $console )->{'data'};
    }
    else {
        $self->Init->io->error("No console in the list");
    }
}

sub error() {
    my $self  = shift;
    my $error = shift;
    if ( $error->content ) {
        $self->Init->io->error( $error->content );
    }

}

sub info() {
    my $self    = shift;
    my @Options = @_;
    $self->call( 'module.info', @Options );
}

sub options() {
    my $self    = shift;
    my @Options = @_;
    $self->call( 'module.options', @Options );

}

sub execute() {
    my $self    = shift;
    my @Options = @_;
    $self->Init->io->debug( "Launching " . join( " ", @Options ) );
    $self->call( 'module.execute', @Options );
}

sub payloads() {
    my $self    = shift;
    my @Options = @_;
    $self->call( 'module.compatible_payloads', @Options );

}

sub login() {
    my $self = shift;
    my $user = $self->Username();
    my $pass = $self->Password();
    my $ret  = $self->call( 'auth.login', $user, $pass );
    $self->Init->io->debug("Logging in with $user and $pass");
    if ( defined($ret) && exists( $ret->{'_msg'} ) ) {
        $self->Init->getIO()
            ->print_alert("Give some time to metas to boot up");
        $self->Init->io->debug_dumper( \$ret );
        return 0;
    }
    elsif ( defined($ret) && $ret->{'result'} eq 'success' ) {

        $self->Token( $ret->{'token'} );
        $self->Auth(1);
        $self->create_console
            if ( !defined $self->currentConsole )
            ;    # Spawning a free console ;)
    }
    else {
        $self->Init->getIO()->debug_dumper($ret);
        $self->Init->getIO()->print_error("Failed auth with MSFRPC");
    }
}

sub parse_result() {
    my $self = shift;

    my $pack = $self->Result;
    if ( exists( $pack->{'error'} ) ) {
        $self->Init->getIO()
            ->print_error("Something went wrong with your MSFRPC call");
        $self->Init->getIO()
            ->print_error( "Backtrace error: " . $pack->{'error_backtrace'} );
        $self->Init->getIO()
            ->print_error( "Message: " . $pack->{'error_message'} );
        foreach my $trace ( $pack->{'error_backtrace'} ) {
            $self->Init->getIO()->print_tabbed( "Backtrace: " . $trace, 2 );
        }
    }
    else {
        if ( exists( $pack->{'job_id'} ) ) {
            $self->Init->getIO()
                ->print_info( "Job ID: " . $pack->{'job_id'} );
        }
        else {
            # $self->Init->getIO()->debug_dumper($pack);
        }
    }
}

1;
