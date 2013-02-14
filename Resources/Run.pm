package Resources::Run;
{
use AnyEvent;
use AnyEvent::Filesys::Notify;
use Nemesis::Inject;
use MooseX::DeclareX;

class Resources::Run{
	nemesis_moosex_resource;
	
	$SIG{'TERM'}=sub { exit; };

	method run(){
		my $cv = AnyEvent->condvar;
		my $notifier = AnyEvent::Filesys::Notify->new(
		    dirs     => [ qw( "/tmp") ],
		    interval => 2.0,             # Optional depending on underlying watcher
		    filter   => sub { shift !~ /\.(swp|tmp)$/ },
		    cb       => sub {
		        my (@events) = @_;
		        print join(" ",@events)."\n";
		        # ... process @events ...
		        $self->Init->getIO()->debug("Testing on ".join(" ",@events));
		    },
		);
	    $cv->recv;
	}
}

}
1;

