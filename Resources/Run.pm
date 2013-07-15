package Resources::Run;
{
    use AnyEvent;
    use AnyEvent::Filesys::Notify;
    use Nemesis::Inject;

    nemesis resource { 1; }

    $SIG{'TERM'} = sub { threads->exit; };

    sub run() {
        my $cv       = AnyEvent->condvar;
        my $notifier = AnyEvent::Filesys::Notify->new(
            dirs => ["/tmp"],

   #   interval => 2.0,             # Optional depending on underlying watcher
   # filter   => sub { shift !~ /\.(swp|tmp)$/ },
            cb => sub {
                my (@events) = @_;
                $self->Init->getIO()->debug_dumper(@events);
            },
        );
        $cv->recv;

    }

}
1;
