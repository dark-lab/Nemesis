#!/usr/bin/perl -w
use warnings;
use Nemesis::Env;
use Nemesis::Interfaces;
use Nemesis::IO;
use Nemesis::Process;
use Nemesis::ModuleLoader;

#External
use Getopt::Long;
use Term::ReadLine;

print q{
	               ,
                      dM
                      MMr
                     4MMML                  .
                     MMMMM.                xf
     .              "M6MMM               .MM-
      Mh..          +MM5MMM            .MMMM
      .MMM.         .MMMMML.          MMMMMh
       )MMMh.        MM5MMM         MMMMMMM
        3MMMMx.     'MMM3MMf      xnMMMMMM"
        '*MMMMM      MMMMMM.     nMMMMMMP"
          *MMMMMx    "MMM5M\    .MMMMMMM=
           *MMMMMh   "MMMMM"   JMMMMMMP
             MMMMMM   GMMMM.  dMMMMMM            .
              MMMMMM  "MMMM  .MMMMM(        .nnMP"
   ..          *MMMMx  MMM"  dMMMM"    .nnMMMMM*
    "MMn...     'MMMMr 'MM   MMM"   .nMMMMMMM*"
     "4MMMMnn..   *MMM  MM  MMP"  .dMMMMMMM""
       ^MMMMMMMMx.  *ML "M .M*  .MMMMMM**"
          *PMMMMMMhn. *x > M  .MMMM**""
             ""**MMMMhx/.h/ .=*"
                      .3P"%....
                    nP"     "*MMnx      [Nemesis is an automated pentest framework powered by weed]
									[just thoughts: what if there is a POE module that passively listen to the network
													and attack when it match some vectors.]
	
	
};
##General Settings
my $env    = new Nemesis::Env;
my $output = new Nemesis::IO(
    debug   => 1,
    verbose => 0,
    env     => $env
);
my $interfaces = new Nemesis::Interfaces( IO => $output );
my $moduleloader = Nemesis::ModuleLoader->new(
    IO         => $output,
    interfaces => $interfaces,
    env        => $env
    )
    ; #Load all plugins in plugin directory and passes to the construtor of the modules those objs
      #

$0 = "spike_nemesis";

$SIG{'INT'} = sub { $output->sighandler(); };

# Setting the terminal
my $prompt    = "Nemesis~# ";
my $term_name = "Nemesis";
my $nemesis_t = new Term::ReadLine($term_name);
$nemesis_t->ornaments(0);

#$output->set_debug(1);
sub usage() {
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
    "host=s"  => \$host,      # string
    "help"    => \$help,
    "verbose" => \$verbose,
    "god"     => \$god
) or usage();
usage() if $help;

if ( defined($verbose) ) {
    $output->verbose(1);
}
else {
    $output->verbose(0);
}

if ( $moduleloader->loadmodules() != 1 ) {    # loadmodules error
    $output->print_error($_);
    exit;
}

#   $moduleloader->execute('Metasploit','test','ARG0','ARG1');

#$moduleloader->listmodules();

if ( defined($god) ) {
    $output->print_info("GodLAN mode on");
    if ( defined($host) ) {
        $lan->lan_attack($host);
    }
    else {
        $lan->lan_attack();
    }
}
else {

}

# Auto-completion with public methods of plugins
my $attribs = $nemesis_t->Attribs;
@PUBLIC_LIST = $moduleloader->export_public_methods();
$attribs->{completion_function} = sub { return @PUBLIC_LIST; };

# Main loop. This is inspired from the POD page of Term::Readline.
while ( defined( $_ = $nemesis_t->readline($prompt) ) ) {
    my @cmd = split( / /, $_ );
    my $command = shift(@cmd);
    if ( $command =~ /\./ ) {
        my ( $module, $method ) = split( /\./, $command );
        if ( "@cmd" =~ /help/i ) { $cmd[0]=$method;$method = 'help'; }
        $moduleloader->execute( $module, $method, @cmd );
    } else {
		$output->debug("not a module command, falling back to eval");
		eval $_;
	}
    warn $@ if $@;
    print "\n";
}

__END__
if ( defined($verbose) ) {
	$output->verbose(1);
}
else {
	$output->verbose(0);
}
if ( defined($host) ) {

}
else {

	$lan->lan_attack();

}
