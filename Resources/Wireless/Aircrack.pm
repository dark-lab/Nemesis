package Resources::Wireless::Aircrack;

use Nemesis::BaseRes -base;

has 'device';

sub airbase {
    my $self = shift;
    my $sw   = "airbase-ng";
    if ( $self->Init->getEnv->is_installed($sw) ) {
        my $Process = $self->Init->ml->atom("Process");
        $Process->set(
            type => "daemon",
            code => $sw . " -P " . $self->device
        );
        $Process->start();
        $self->Process($Process);
        $self->Init->io->process_status($Process);
        return 1;
    }
    else {
        return 0;
    }

}

!!42;
