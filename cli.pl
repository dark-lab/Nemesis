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


use Getopt::Long;
use Term::ReadLine::Gnu;
##General Settings
my $Init         = new Nemesis::Init();
my $output       = $Init->getIO();
my $moduleloader = $Init->getModuleLoader();
$output->print_ascii( 'ascii/logo.txt', "red on_black bold" );
$output->print_ascii( 'ascii/motd.txt', "red on_black bold" );
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
