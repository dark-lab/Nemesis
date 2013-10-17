package Resources::Wireless::Aircrack;

use Nemesis::BaseRes -base;

has 'device';
has 'Process';

sub airbase {
    my $self = shift;
    my $sw   = "airbase-ng";

    $self->Init->io->exec("modprobe tun");

    #Necessary

    if ( $self->Init->getEnv->is_installed($sw) ) {
        my $Process = $self->Init->ml->atom("Process");
        $Process->set(
            type => "fork",
            code => $sw . " -v -P " . $self->device
        );
        $Process->start();
        $self->Process($Process);
        $self->Init->io->info("Airbase started");
        #$self->Init->io->process_status($Process);
        return 1;
    }

    return 0;

}

!!42;
