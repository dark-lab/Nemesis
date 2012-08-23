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

##General Settings
my $env    = new Nemesis::Env;
my $output = new Nemesis::IO(
    debug   => 1,
    verbose => 0,
    env     => $env
);
$output->print_motd();
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
my $prompt    = $output->get_prompt_out();
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
    "god"     => \$god,
    "status"  => \$status
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

if ( defined($status) )

{

    use Curses::UI;
    $Curses::UI::debug = 0;

    my $cui = new Curses::UI( -color_support => 1 );
    my $info = $cui->add(
        undef, 'Window',
        -y         => -1,
        -height    => -1,
        -width     => -1,
        -border    => 1,
        -padbottom => 3,
        -bfg       => 'red',
    );
    my $sw = $cui->add(
        undef, 'Window',
        -y => -1,

        -height => 3,
        -width  => -1,
        -border => 1,
        -bfg    => 'red'
    );
    my $status = $sw->add(
        undef, 'Label',
        -width    => -1,
        -padright => 8,
    );
    my $status2 = $info->add(
        undef, 'Label',
        -width  => -1,
        -height => -1,
    );

    $cui->set_binding( sub { exit 0; }, "q" );
    my $i = 0;

    #$cui->mainloop;
    while ( sleep 1 ) {

        $status->text(time);

        &check_label( $status2, "MERDA" . $i++ );

        #$status2->text($status2->text()."\n".$status2->height()."\r\n");

        $cui->draw();
    }

    sub check_label() {
        my $label = $_[0];
        my $text  = $_[1];
        my $h     = $label->height() - 1;
        my $w     = $label->width();
        my $cut;
        my $lunghezza   = length($text);
        my $text_to_set = $text;
        if ( $lunghezza >= $w ) {
            my $differenza = $lunghezza - $w;
            my $cut = substr $text, -$differenza, "";
            $text_to_set = substr $text, $w, "";
        }
        my $current_text = $label->text();
        my $lines        = 0;
        while ( $current_text =~ m/\n/g ) {
            $lines++;
        }

        #print($lines."Le linee...\n");

        if ( $lines > $h ) {
            my @out = split( /\n/, $current_text );
            chomp(@out);
            my $diff2 = $lines - $h;
            my $n     = 1;
            for ( $n = 1; $diff2 >= $n; $n++ ) {
                shift(@out);
            }
            push( @out, $text_to_set );
            my $o = "";
            foreach my $gen (@out) {
                $o .= $gen . "\n";
            }
            $label->text($o);

        }
        else {
            if ( $current_text ne "" ) {
                $label->text( $current_text . "\n" . $text_to_set );
            }
            else {
                $label->text($text_to_set);
            }
        }
        if ( defined($cut) ) {
            &check_label( $label, $cut );
        }
    }

}
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
my $list = join( " ", @PUBLIC_LIST );

# Main loop. This is inspired from the POD page of Term::Readline.
while ( defined( $_ = $nemesis_t->readline($prompt) ) ) {
    my @cmd = split( / /, $_ );
    my $command = shift(@cmd);
    if ( $command eq "reload" ) {
        $output->print_title("Reloading modules..");
        if ( $moduleloader->loadmodules() != 1 ) {    # loadmodules error
            $output->print_error($_);
            exit;
        }
        @PUBLIC_LIST = $moduleloader->export_public_methods();
    }
    elsif ( $command =~ /exit/ ) {
        $output->print_info("Clearing all before we go..");
        $moduleloader->execute_on_all("clear");
        exit;

    }
    elsif ( $command =~ /\./ ) {
        my ( $module, $method ) = split( /\./, $command );
        if ( "@cmd" =~ /help/i ) { $cmd[0] = $method; $method = 'help'; }
        if ( $list =~ /$command/i ) {
            $moduleloader->execute( $module, $method, @cmd );
        }
        else {
            $output->print_alert("function not implemented");
        }
    }
    else {
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
