#!/usr/bin/perl
#use Term::ReadLine;
use Nemesis;

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
#!/usr/bin/perl -W

use Carp;
use POE;
use Term::Visual;


my $Init         = new Nemesis::Init();

my $vt = Term::Visual->new( Alias => "interface" );
 $vt=$Init->getIO->setVt($vt);
POE::Session->create
  (inline_states =>
    { _start         => \&start_guts,
      got_term_input => \&handle_term_input,
      update_time    => \&update_time,
      update_name    => \&update_name,
      load_all       => \&load_all,
      test_buffer    => \&test_buffer,
      _stop          => \&stop_guts,
    }
  );



#$vt->print($window_id, $Init->getIO->print_ascii_fh(*DATA,"logo"));

$Init->getIO->print_ascii_fh(*DATA,"logo");   


$SIG{'INT'} = sub { $Init->sighandler(); };


# Setting the terminal
#@PUBLIC_LIST = $Init->getModuleLoader->export_public_methods();


#$Init->getSession()->wrap_history($nemesis_t);


$Init->getIO()->print_info("Press CTRL+L to clear screen");


#$vt->print($window_id, $vt->get_palette);
#$vt->print($window_id, "---------------------------------------");
#$vt->print($window_id, $vt->get_palette("st_values", "ncolor"));
#$vt->debug("testing debugging");
## Initialize the back-end guts of the "client".
$poe_kernel->run();

#$vt->shutdown;
exit 0;

sub start_guts {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  # Tell the terminal to send me input as "got_term_input".
  $kernel->post( interface => send_me_input => "got_term_input" );

  $vt=$Init->getIO->setVt($vt); #Only coz we have VT$vt=$Init->getIO->setVt($vt); #Only coz we have VT
  $Init->checkroot();
  # Start updating the time.
    $kernel->yield( "update_time" );
  $kernel->yield( "update_name" );
    $kernel->yield( "load_all" );



 #$vt->set_input_prompt($window_id, "\$");
#  $kernel->yield( "test_buffer" );
#  $vt->shutdown;
}

sub load_all{
    $Init->getModuleLoader()->loadmodules();
}

### The main input handler for this program.  This would be supplied
### by the guts of the client program.

sub handle_term_input {
#  beep();
  my ($kernel, $heap, $input, $exception) = @_[KERNEL, HEAP, ARG0, ARG1];
chomp($input);
$Init->getIO()->parse_cli($input);


  # Got an exception.  These are interrupt (^C) or quit (^\).
 if (defined $exception) {
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
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  $vt->set_status_field( $vt->current_window, time => $Init->getEnv()->time_seconds() );

  # Schedule another time update for the next minute.  This is more
  # accurate than using delay() because it schedules the update at the
  # beginning of the minute.
  $kernel->alarm( update_time => int(time() / 60) * 60 + 60 );
}

sub update_name {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  my $window_name = $vt->get_window_name($vt->current_window);
  $vt->set_status_field( $vt->current_window, name => $Init->getIO->get_prompt_out );
}

my $i = 0;
sub test_buffer {
   my ($kernel, $heap) = @_[KERNEL, HEAP];
  $i++;
  $vt->print($$vt->current_window, $i);
  $kernel->alarm( test_buffer => int(time() / 60) * 60 + 20 ); 
}

sub stop_guts {
  my ($kernel, $heap) = @_[KERNEL, HEAP];
  $vt->shutdown;
  $kernel->alarm_remove_all();
  if (defined $heap->{input_session}) {
    delete $heap->{input_session};
  }

}





__DATA__
                                                                                           
                                                                                           
  L.                      ,;                                ,;           .                .
  EW:        ,ft        f#i                               f#i           ;W  t            ;W
  E##;       t#E      .E#t              ..       :      .E#t           f#E  Ej          f#E
  E###t      t#E     i#W,              ,W,     .Et     i#W,          .E#f   E#,       .E#f 
  E#fE#f     t#E    L#D.              t##,    ,W#t    L#D.          iWW;    E#t      iWW;  
  E#t D#G    t#E  :K#Wfff;           L###,   j###t  :K#Wfff;       L##Lffi  E#t     L##Lffi
  E#t  f#E.  t#E  i##WLLLLt        .E#j##,  G#fE#t  i##WLLLLt     tLLG##L   E#t    tLLG##L 
  E#t   t#K: t#E   .E#L           ;WW; ##,:K#i E#t   .E#L           ,W#i    E#t      ,W#i  
  E#t    ;#W,t#E     f#E:        j#E.  ##f#W,  E#t     f#E:        j#E.     E#t     j#E.   
  E#t     :K#D#E      ,WW;     .D#L    ###K:   E#t      ,WW;     .D#j       E#t   .D#j     
  E#t      .E##E       .D#;   :K#t     ##D.    E#t       .D#;   ,WK,        E#t  ,WK,      
  ..         G#E         tt   ...      #G      ..          tt   EG.         E#t  EG.       
              fE                       j                        ,           ,;.  ,         
               ,                                                

                            dHP^~"        "~^THb.
                          .AHF                YHA.  
                         .AHHb.              .dHHA.  
                         HHAUAAHAbn      adAHAAUAHA  
                         HF~"_____        ____ ]HHH 
                         HAPK""~^YUHb  dAHHHHHHHHHH
                         HHHD> .andHH  HHUUP^~YHHHH
                         ]HHP     "~Y  P~"     THH[ 
                         `HK                   ]HH'  
                          THAn.  .d.aAAn.b.  .dHHP
                          ]HHHHAAUP" ~~ "YUAAHHHH[
                          `HHP^~"  .annn.  "~^YHH'
                           YHb    ~" "" "~    dHF
                            "YAb..abdHHbndbndAP"
                              THHAAb.  .adAHHF
                              "UHHHHHHHHHHU"     
                                ]HHUUHHHHHH[
                              .adHHb "HHHHHbn.
                       ..andAAHHHHHHb.AHHHHHHHAAbnn..
                  .ndAAHHHHHHUUHHHHHHHHHHUP^~"~^YUHHHAAbn.
                    "~^YUHHP"   "~^YUHHUP"        "^YUP^"
                         ""         "~~"
