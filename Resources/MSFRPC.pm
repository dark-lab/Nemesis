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
    has 'Auth' => (isa=>'Int',is=>'rw', default => 0);
    has 'Result' => (is=>"rw");
    nemesis_resource;

	method call (@Options){
        my $meth = shift @Options;
        my $UserAgent   = LWP::UserAgent->new;
        my $MessagePack = Data::MessagePack->new();
       # $self->Init->getIO()->debug("Method $meth");
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
      #  $self->Init->getIO->debug_dumper($res);
        return $res if $res->code == 500 or $res->code != 200;

        $self->Result($MessagePack->unpack( $res->content ));
              #  $self->parse_result();

        return $MessagePack->unpack( $res->content );
	}

    method info(@Options){
        $self->call('module.info',@Options);
    }
    method options(@Options){
        $self->call('module.options',@Options);
    }

    method login(){
        my $user = $self->Username();
        my $pass = $self->Password();
        my $ret  = $self->call( 'auth.login', $user, $pass );
        if(defined ($ret)  && exists($ret->{'_msg'}) ){
            $self->Init->getIO()->print_alert("Give some time to metas to boot up");
            return 0;
        }
        elsif ( defined ($ret)  && $ret->{'result'} eq 'success' ) {

            $self->Token($ret->{'token'});
            $self->Auth(1);
        }
        else {
            $self->Init->getIO()->debug_dumper($ret);
            $self->Init->getIO()->print_error("Failed auth with MSFRPC");
        }
    }
    method parse_result() {
        my $pack = $self->Result;
        if ( exists( $pack->{'error'} ) ) {
            $self->Init->getIO()
                ->print_error("Something went wrong with your MSFRPC call");
            $self->Init->getIO()->print_error( "Backtrace error: " . $pack->{'error_backtrace'} );
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