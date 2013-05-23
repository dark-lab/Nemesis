package Nemesis::Init;
{

    sub new {
        my $package = shift;
        bless( {}, $package );
        $package->{'Env'} = new Nemesis::Env( Init => $package );
        $package->{'Session'} = new Nemesis::Session( Init => $package );
         $package->{'ModuleLoader'} =
            new Nemesis::ModuleLoader( Init => $package );
        if ( $package->{'Session'}->exists("default_session") ) {
            $package->{'Session'}->restore("default_session");
        }
        else {
            $package->{'Session'}->initialize("default_session");
            $Session->restore("default_session");
        }
        $package->{'Io'} = new Nemesis::IO(
            debug   => 1,
            verbose => 0,
            Init    => $package
        );
        $package->{'Interfaces'} =
            new Nemesis::Interfaces( Init => $package );
        

       
        $0 = "SpikeNemesis";
        return $package;
    }

    sub sighandler() {
        my $self = shift;
        $self->on_exit();
    }

    sub on_exit() {
        my $self = shift;
        if ( exists( $self->{'Session'} ) ) {

            #	$self->{'Session'}->save();
        }
        $self->{'ModuleLoader'}->execute_on_all("clear");
        exit;
    }

    sub getIO {
        my $package = shift;
        return $package->{'Io'};
    }

    sub io{
        my $package = shift;
        return $package->{'Io'};
    }

    sub getEnv {
        my $package = shift;
        return $package->{'Env'};
    }

    sub env{
        my $package = shift;
        return $package->{'Env'};
    }

    # sub getPacker {
    #     my $package = shift;
    #     return $package->{'Packer'};
    # }

    sub getInterfaces {
        my $package = shift;
        return $package->{'Interfaces'};
    }
    sub interfaces {
        my $package = shift;
        return $package->{'Interfaces'};
    }

    sub getSession {
        my $package = shift;
        return $package->{'Session'};
    }

    sub session {
        my $package = shift;
        return $package->{'Session'};
    }

    sub getModuleLoader {
        my $package = shift;
        return $package->{'ModuleLoader'};
    }

    sub moduleloader {
        my $package = shift;
        return $package->{'ModuleLoader'};
    }

    sub ml {
        my $package = shift;
        return $package->{'ModuleLoader'};
    }

    sub checkroot() {
        my $package = shift;
        if ( !$package->{'Env'}->check_root() ) {
            $package->{'Io'}->print_alert(
                "Insufficient permission, something can go really wrong switching to debug mode"
            );
            $package->{'Io'}->set_debug(1);    #If no root given, debug on
        }
    }
}
1;
