package Nemesis::IO;
use warnings;
use Term::UI;    #VOGLIO PASSARE A IO LA FUNZIONE di term::readline
use Term::ANSIColor;

sub new {
    my $package = shift;
    bless( {}, $package );
    my (%config) = @_;
    %{ $package->{'CONFIG'} } = %config;

    #open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
    #open STDOUT, '>>/dev/null';
    open STDERR, '>>/dev/null';

    umask 0;
    $package->debug("Nemesis::IO loaded");

    return $package;
}

sub get_completion_color {

    return colored( '->', 'cyan bold on_black' );

}

sub get_prompt_out {

    return
          colored( "Nemesis", "green on_black" )
        . colored( "~",  "white on_black" )
        . colored( "# ", "blue on_black blink" );

}

sub print_motd {

    print colored(
        q{ 	               ,
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
	
		
	}, "blue on_black bold"
    ) . "\n";
}

sub set_public_methods() {
    my $self = shift;
    $self->{'PUBLIC_METHOD'} = @_;

}

sub print_alert() {
    my $self = shift;
    print colored( "[",    "magenta on_black bold" )
        . colored( "Warn", "green on_black bold" )
        . colored( "]\t",  "magenta on_black bold" )
        . colored( $_[0],  "cyan on_black" ) . "\n";

    # print "\/\!\\ Nemesis Warning \/\!\\\t " . $_[0] . "\n";

}

sub print_verbose() {

    my $self = shift;
    my $text = $_[0];
    if ( $self->{'CONFIG'}->{'verbose'} == 1 ) {
        print "[! Nemesis Verbose !]\t" . $text . "\n";
    }
}

sub sighandler() {
    my $self = shift;
    $self->print_alert("Caught a nice signal... this was a good one");
}

sub debug() {
    my $self = shift;
    if ( $self->{'CONFIG'}->{'debug'} == 1 ) {

        print colored( "[",     "magenta on_black bold" )
            . colored( "DEBUG", "bold on_red white" )
            . colored( "]\t",   "magenta on_black bold" )
            . colored( $_[0],   "bold on_red white" ) . "\n"
            . colored( "\tat " . $self->{'CONFIG'}->{'env'}->time_seconds(),
            "bold on_black cyan" )
            . "\n";

        #    print "["
        #       . $self->{'CONFIG'}->{'env'}->time_seconds()
        #      . "]\t"
        #      . $_[0] . "\n";
    }
}

sub print_info() {
    my $self = shift;
    print colored( "[",   "magenta on_black bold" )
        . colored( "**",  "green on_black bold" )
        . colored( "]\t", "magenta on_black bold" )
        . colored( $_[0], "blue on_black bold" ) . "\n";

    #print( colored( "~>\t", "green on_black bold" ),
    #colored( $_[0], "blue on_black bold" ), "\n" );
    #print "["
    #    . $self->{'CONFIG'}->{'env'}->time_seconds() . "]>\t"
    #    . $_[0] . "\n";
}

sub print_error() {
    my $self = shift;

    print colored( "[ERROR]\t", "bold red on_black blink" )
        . colored(
        "[" . $self->{'CONFIG'}->{'env'}->time_seconds() . "]\n" . $_[0],
        "bold red on_black" )
        . "\n";

    #  print "["
    #      . $self->{'CONFIG'}->{'env'}->time_seconds()
    #     . "] !!! Nemesis Error !!!\t"
    #     . $_[0] . "\n";

}

sub print_tabbed {
    print( colored( "\t~> ", "green on_black bold" ),
        colored( $_[1], "blue on_black bold" ), "\n" );

}

sub print_title {
    my $self = shift;
    my ($msg) = @_;
    printf "\n\n";

    #printf colored("=" x length($msg),"white on_yellow");
    printf "\n" . colored( $msg, "yellow on_black bold" ) . "\n";
    printf colored( "=" x length($msg), "white on_yellow" );
    printf "\n\n";
}

sub shell() {

    #qui invece aprirà una shell

}

sub exec() {
    my $self    = shift;
    my $command = $_[0];
    my $env     = $self->{'CONFIG'}->{'env'};
    my @output;
    my @path = $env->path();
    my @commands;
    my $final;
    if ( $command =~ /;/ ) {
        @commands = split( /;/, $command );
        foreach my $comm (@commands) {
            $final .= $self->generate_command($comm);
            $final .= ";";
        }
    }
    else {

        $final = $self->generate_command($command);
    }

    my $cwd = $env->workspace();
    @output = `cd $cwd;$final`;
    chomp(@output);
    return @output;

}

sub verbose() {
    my $self = shift;
    $self->print_info( "Verbose mode " . $_[0] );
    $self->{'CONFIG'}->{'verbose'} = $_[0];

}

sub set_debug() {
    my $self = shift;
    $self->print_info( "Debug mode " . $_[0] );
    $self->{'CONFIG'}->{'debug'} = $_[0];

}

sub generate_command() {
    my $self    = shift;
    my $command = $_[0];
    my $env     = $self->{'CONFIG'}->{'env'};
    my @path    = $env->path();

    if ( $command =~ / / ) {

        my @tmp_c = split( / /, $command );

        my $pp;

        #foreach my $tmp (@tmp_c) {
        $tmp = shift(@tmp_c);
        foreach my $p (@path) {
            $pp = $p;
            if ( -e "$p/$tmp" && $tmp !~ /\// )
            { #serve per ritrovare il programma di lancio e aggiungergli la path assoluta davanti
                if ( $pp =~ /\/$/ && $tmp =~ /^\// ) {
                    chop($pp);
                }
                $tmp = $pp . '/' . $tmp;
            }
        }

        #}
        $command = $tmp . " @tmp_c";
    }
    else {
        my $stop = 0;
        foreach my $p (@path) {
            next if $stop == 1;
            $pp = $p;
            if ( -e "$p/$command" && $command !~ /\// )
            { #serve per ritrovare il programma di lancio e aggiungergli la path assoluta davanti
                if ( $pp =~ /\/$/ && $command =~ /^\// ) {
                    chop($pp);
                }
                $command = $pp . '/' . $command;
                $stop    = 1;
            }
        }
    }

    return $command;
}

1;
__END__
