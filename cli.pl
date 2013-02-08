#!/usr/bin/perl -w
use warnings;

use Nemesis::Init;

#NOTE:
#http://search.cpan.org/~flora/Devel-Declare-0.006006/lib/Devel/Declare.pm
#http://search.cpan.org/~flora/B-Hooks-Parser-0.09/lib/B/Hooks/Parser.pm
#Guarda test.pl nella home
#External

#TODO: Valutare Net:Interface ?
#use strict;
#TODO: TheNet
#TODO: Valutare l'inclusione di http://search.cpan.org/~reedfish/Net-FullAuto-0.999944/lib/Net/FullAuto.pm
#Net:Route

#TODO: Abilitare il supporto Moose per i moduli (Ovvero che i moduli come ad esempio metasploit.pm possono essere formato moose)
#Dunque KiokuDB per i moduli moose.

# TODO: IstanceExporter: comprimere i moduli con App::qualcosa, usare acme, esportare ed eseguire con un modulo di reverse shell sulla cli

use Getopt::Long;
use Term::ReadLine::Gnu;
##General Settings
my $Init         = new Nemesis::Init();
my $output       = $Init->getIO();
my $moduleloader = $Init->getModuleLoader();
$output->print_ascii_fh(*DATA,"red on_black bold");
$Init->{'Interfaces'}->print_devices();
$Init->checkroot();
$SIG{'INT'} = sub { $Init->sighandler(); };

# Setting the terminal
my $term_name = "Nemesis";
my $nemesis_t = new Term::ReadLine($term_name);

sub usage()
{
	$output->print_info("$0 - Nemesis Pentest Framework -");
	$output->print_info(
		"$0 [--host some.host] [--help] [--verbose] [--stealthy] [--passive] [--evil]"
	);
	$output->print_info(
		"\t--host: a modality targeted to a host (evaluating also all the relationships between the host and the lan)"
	);
	$output->print_info(
		"\t--stealthy: Stealthy aquire the power of the network witouth being busted"
	);
	$output->print_info(
				  "\t--passive: Capture all infos about the network passively");
	$output->print_info("\t--god: All the net in your hands!");
	$output->print_info(
		  "\t--evil: All the net in your hands! ---------- And now, let's rock!"
	);
	exit();
}
my $result = GetOptions(    #"length=i" => \$length,    # numeric
						 "help"    => \$help,
						 "verbose" => \$verbose,
) or usage();
usage() if $help;
if ( defined($verbose) )
{
	$output->verbose(1);
}
if ( $moduleloader->loadmodules() != 1 )
{                           # loadmodules error
	$output->print_error($_);
	exit;
}

#   $moduleloader->execute('Metasploit','test','ARG0','ARG1');
#$moduleloader->listmodules();
# Auto-completion with public methods of plugins
my $attribs = $nemesis_t->Attribs;
@PUBLIC_LIST = $moduleloader->export_public_methods();
$attribs->{completion_function} = sub { return @PUBLIC_LIST; };
my $list = join( " ", @PUBLIC_LIST );

$Init->getSession()->wrap_history($nemesis_t);

# Main loop. This is inspired from the POD page of Term::Readline.
while ( defined( $_ = $nemesis_t->readline( $output->get_prompt_out() ) ) )
{
	my @cmd = split( /\s*("[^"]+"|[^\s"]+)/, $_ );
	@cmd = $output->sanitize(@cmd);    #Depure from evil!
	shift(@cmd);
	my $command = shift(@cmd);
	next if !$command;
	if ( $command eq "reload" )
	{
		$output->print_title("Reloading modules..");
		if ( $moduleloader->loadmodules() != 1 )
		{                              # loadmodules error
			$output->print_error($_);
			exit;
		}
		@PUBLIC_LIST = $moduleloader->export_public_methods();
	} elsif ( $command =~ /exit/ )
	{
		$Init->on_exit();
	} elsif ( $command =~ /clear/ )
	{
		$nemesis_t->clear_message();
	} elsif ( $command =~ /\./ )
	{
		my ( $module, $method ) = split( /\./, $command );
		if ( "@cmd" =~ /help/i ) { $cmd[0] = $method; $method = 'help'; }
		if ( $list =~ /$command/i and $method ne "" )
		{
			$moduleloader->execute( $module, $method, @cmd );
		} else
		{
			$output->print_alert("function not implemented");
		}
	} else
	{
		#$moduleloader->execute( "shell", "run", $command, @cmd );
		eval($command." ".join(" ",@cmd));
	}
	warn $@ if $@;
	print "\n";
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
