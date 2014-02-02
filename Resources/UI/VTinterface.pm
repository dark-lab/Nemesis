package Resources::UI::VTinterface;

#use Term::ReadLine;
use Carp;
use POE;
use Term::Visual;
use Resources::Logo;
use Nemesis::BaseRes -base;

#NOTE:
#http://search.cpan.org/~flora/Devel-Declare-0.006006/lib/Devel/Declare.pm
#http://search.cpan.org/~flora/B-Hooks-Parser-0.09/lib/B/Hooks/Parser.pm
#http://perlbrew.pl/
#TODO: Valutare Net:Interface ?
#use strict;
#TODO: Valutare l'inclusione di http://search.cpan.org/~reedfish/Net-FullAuto-0.999944/lib/Net/FullAuto.pm
#Net:Route
#ANN, SVM, DecisionTree?
#Dunque KiokuDB per i moduli moose KiokuX::Model e Search::GIN ? KiokuDB::LiveObjects?
#XXX:https://metacpan.org/module/KiokuDB
#https://metacpan.org/module/KiokuDB::Tutorial
#Websploit? dsniff?

sub run() {
    my $self = shift;
   # $self->Init->io->print_info("Starting");

    #$vt->print($window_id, $Init->getIO->print_ascii_fh(*DATA,"logo"));

    # Setting the terminal
    #@PUBLIC_LIST = $Init->getModuleLoader->export_public_methods();

    #$Init->getSession()->wrap_history($nemesis_t);

    #$vt->print($window_id, $vt->get_palette);
    #$vt->print($window_id, "---------------------------------------");
    #$vt->print($window_id, $vt->get_palette("st_values", "ncolor"));
    #$vt->debug("testing debugging");
## Initialize the back-end guts of the "client".

    my $vt = Term::Visual->new( Alias => "interface" );
    POE::Session->create(
        inline_states => {
            _start         => \&start_guts,
            got_term_input => \&handle_term_input,
            update_time    => \&update_time,
            update_name    => \&update_name,
            load_all       => \&load_all,
            test_buffer    => \&test_buffer,
            _stop          => \&stop_guts,
        },
        heap => { 'vt' => $vt, 'Init' => $self->Init },

    );

    $poe_kernel->run();

}

sub start_guts {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    my $vt   = $heap->{'vt'};
    my $Init = $heap->{'Init'};

    # Tell the terminal to send me input as "got_term_input".
    $kernel->post( interface => send_me_input => "got_term_input" );
    $vt = $Init->getIO->setVt($vt);
    $Init->checkroot();
    $kernel->yield("update_name");
    $kernel->yield("update_time");

    # Start updating the time.
    $kernel->yield("load_all");

    #$vt->set_input_prompt($window_id, "\$");
    #  $kernel->yield( "test_buffer" );
    #  $vt->shutdown;
}

sub load_all {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    my $vt   = $heap->{'vt'};
    my $Init = $heap->{'Init'};
    $Init->getIO->print_ascii_fh( *Resources::Logo::DATA, "logo" );
    $Init->getModuleLoader()->loadmodules();
    $Init->getIO()->print_info("Press CTRL+L to clear screen");

}

### The main input handler for this program.  This would be supplied
### by the guts of the client program.

sub handle_term_input {

    #  beep();
    my ( $kernel, $heap, $input, $exception )
        = @_[ KERNEL, HEAP, ARG0, ARG1 ];
    chomp($input);

    my $vt   = $heap->{'vt'};
    my $Init = $heap->{'Init'};
    $Init->getIO()->parse_cli($input);

    # Got an exception.  These are interrupt (^C) or quit (^\).
    if ( defined $exception ) {
        $Init->getIO()->print_error($exception);
        exit;
    }

    #if ($input eq 'quit') {
    # $kernel->yield('_stop');
    #}
    #else {
    #$vt->print($window_id, $input);
    #}
}

### Update the time on the status bar.

sub update_time {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    my $vt   = $heap->{'vt'};
    my $Init = $heap->{'Init'};
    $vt->set_status_field( $vt->current_window,
        time => $Init->getEnv()->time_seconds() );

    # Schedule another time update for the next minute.  This is more
    # accurate than using delay() because it schedules the update at the
    # beginning of the minute.
    $kernel->alarm( update_time => int( time() / 60 ) * 60 + 60 );
}

sub update_name {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    my $vt          = $heap->{'vt'};
    my $Init        = $heap->{'Init'};
    my $window_name = $vt->get_window_name( $vt->current_window );
    $vt->set_status_field( $vt->current_window,
        name => $Init->getIO->get_prompt_out );
}

sub test_buffer {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    my $i = 0;

    my $vt   = $heap->{'vt'};
    my $Init = $heap->{'Init'};
    $i++;
    $vt->print( $$vt->current_window, $i );
    $kernel->alarm( test_buffer => int( time() / 60 ) * 60 + 20 );
}

sub stop_guts {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    my $vt   = $heap->{'vt'};
    my $Init = $heap->{'Init'};
    $vt->shutdown;
    $kernel->alarm_remove_all();
    if ( defined $heap->{input_session} ) {
        delete $heap->{input_session};
    }

}
1;
