package Resources::Wireless::Aircrack;

use Nemesis::BaseRes -base;

has 'device';
has 'Process';
has 'monitor_device';

sub airbase {
    my $self = shift;

    my $mode = shift || 0;

    my $sw = "airbase-ng";

    if ( $mode == 1 ) {

        $self->Init->io->exec("modprobe tun");

        #Necessary

        if ( $self->Init->getEnv->is_installed($sw) ) {
            my $Process = $self->Init->ml->atom("Process");
            $Process->set(
                type => "fork",
                code => $sw . " -v -P " . $self->monitor_device
            );
            $Process->start();
            $self->Process($Process);
            $self->Init->io->info("Airbase started");

            #$self->Init->io->process_status($Process);
            return 1;
        }

    }
    elsif ( $mode == 0 ) {
        return 1 if ( defined $self->Process and $self->Process->destroy() );

    }

    return 0;

}

sub monitor { # accetta il parametro mode : 1/0 disabilita abilita monitor mode sulla device definita nell'attributo
    my $self = shift;
    my $mode = shift || 0;
    my $sw   = "airmon-ng";
    my $opt1 = $sw . " check kill";
    my $opt2 = $sw . " start " . $self->device;

    if ( $mode == 1 ) {

        if ( defined $self->monitor_device ) {
            $self->Init->io->info(
                "You already have " . $self->device . " in monitor mode" );
            return 1;

        }
        else {

            if ( my @Res = $self->Init->io->exec($opt1) ) {
                if ( "@Res" =~ /Killing/ ) {
                    $self->Init->io->info(
                        "Killing all processes associated with your devices");

                    if ( my @Res = $self->Init->io->exec($opt2) ) {
                        foreach my $line (@Res) {
                            if ( $line =~ /enabled\s+on\s(.*)\)/i ) {
                                $self->monitor_device($1);
                                $self->Init->io->info(
                                    "Enabled monitor mode on "
                                        . $self->monitor_device );
                                return 1;
                            }
                        }

                    }

                }
            }

        }

    }
    elsif ( defined $self->monitor_device and $mode == 0 ) {

        if ( my @Res
            = $self->Init->io->exec( $sw . " stop " . $self->monitor_device )
            )
        {

            if ( "@Res" =~ /removed/i ) {
                $self->Init->io->info( "Removing " . $self->monitor_device );
                $self->monitor_device("");
                return 1;

            }

        }

    }
    return 0;

}

!!42;
