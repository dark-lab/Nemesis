package Resources::MSFRPC;
use MooseX::Declare;
use Nemesis::Inject;

class Resources::MSFRPC{
    require Data::MessagePack;
    require LWP;
    require HTTP::Request;

	has 'Username' => (isa=>'Str', is=>'rw', default=>'spike');
	has 'Password' => (isa=>'Str', is=>'rw', default=>'spiketest');
	has 'Host' => (isa=>'Str', is=>'rw', default=>'127.0.0.1');
	has 'Port' => (isa=>'Int', is=>'rw', default=>5553);
	has 'API' => (isa=>'Str', is=>'rw', default=>'/api/');
    has 'Token' => (is=>'rw');
    has 'Auth' => (isa=>'Int',is=>'rw');
    nemesis_moosex_resource;

	method call (Str $meth,ArrayRef[Str] @Options){
        my $UserAgent   = LWP::UserAgent->new;
        my $MessagePack = Data::MessagePack->new();
        my $URL =
              'http://'
            . $self->Host . ":"
            . $self->Port
            . $self->API;
        if ( $meth ne 'auth.login' and $self->Auth != 1) {
            $self->login();
        }
        unshift @Options, $self->Token() if ( $self->Token() );
        unshift @Options, $meth;
        my $HttpRequest = new HTTP::Request( 'POST', $URL );
        $HttpRequest->content_type('binary/message-pack');
        $HttpRequest->content( $MessagePack->pack( \@Options ) );
        my $res = $UserAgent->request($HttpRequest);
        $self->parse_result($res);
        return 0 if $res->code == 500 or $res->code != 200;
        $self->Init->getIO()->debug_dumper( $MessagePack->unpack( $res->content ) );
        return $MessagePack->unpack( $res->content );
	}

    method login(){
        my $user = $self->Username();
        my $pass = $self->Password();
        my $ret  = $self->call( 'auth.login', $user, $pass );
        if ( $ret->{'result'} eq 'success' ) {
            $self->Token($ret->{'token'});
            $self->Auth(1);
        }
        else {
            $self->Init->getIO()->debug_dumper($ret);
            $self->Init->getIO()->print_error("Failed auth with MSFRPC");
        }
    }
    method parse_result() {

        my $pack = $_[0];
        if ( exists( $pack->{'error'} ) ) {
            $self->Init->getIO()
                ->print_error("Something went wrong with your MSFRPC call");
            $self->Init->getIO()->print_error( "Code error: " . $pack->{'error_code'} );
            $self->Init->getIO()->print_error( "Message: " . $pack->{'error_message'} );
            foreach my $trace ( $pack->{'error_backtrace'} ) {
                $self->Init->getIO()->print_tabbed( "Backtrace: " . $trace, 2 );
            }
        }
        else {
            if ( exists( $pack->{'job_id'} ) ) {
                $self->Init->getIO()->print_info( "Job ID: " . $pack->{'job_id'} );
            } else {
                $self->Init->getIO()->debug_dumper($pack);
            }
        }
    }

}