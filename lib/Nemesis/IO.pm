package Nemesis::IO;
use warnings;
use Term::UI;    #VOGLIO PASSARE A IO LA FUNZIONE di term::readline
use Term::ANSIColor;
use Data::Dumper;
use Carp qw( croak );
our $Init;

sub new {
    my $package = shift;
    bless( {}, $package );
    %{$package} = @_;
    $Init = $package->{'Init'};

    #open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
    # open STDOUT, '>>/dev/null';
    # open STDERR, '>>/tmp/nemesis_log.txt';
    umask 0;
    return $package;
}

sub parse_cli() {
    my $self        = shift;
    my $Input       = $_[0];
    my @PUBLIC_LIST = $Init->getModuleLoader()->export_public_methods();
    my $list        = join( " ", @PUBLIC_LIST );
    my @cmd         = split( /\s*("[^"]+"|[^\s"]+)/, $Input );
    @cmd = $self->sanitize(@cmd);    #Depure from evil!
    shift(@cmd);
    my $command = shift(@cmd);
    return if !$command;
    $self->print_title( "< " . $command . " " . join( " ", @cmd ) . " >" );

    if ( $command eq "reload" ) {
        $self->print_title("Reloading modules..");
        $Init->ml()->loadmodules();

    }
    elsif ( $command =~ /exit/ ) {
        $Init->on_exit();
    }
    elsif ( $command =~ /\./ ) {
        my ( $module, $method ) = split( /\./, $command );
        if ( "@cmd" =~ /help/i ) { $cmd[0] = $method; $method = 'help'; }
        if ( $list =~ /$command/i and $method ne "" ) {
            if ( scalar(@cmd) != 0 ) {
                $Init->getModuleLoader()->execute( $module, $method, @cmd );
            }
            else {
                $Init->getModuleLoader()->execute( $module, $method );
            }
        }
        else {
            $self->print_alert("function not implemented");
        }
    }
    else {
        $Init->getModuleLoader()->execute( "shell", "run", $command, @cmd );

        #eval($command." ".join(" ",@cmd));
    }
    warn $@ if $@;

    # print "\n";
}

sub get_completion_color {
    return colored( '->', 'cyan bold on_black' );
}

sub setVt() {
    my $self = shift;

    my $vt = $_[0];
    $vt->set_palette(
        squareb       => "magenta on black",
        logo          => "red on black bold",
        warn          => "green on black bold",
        warntext      => "cyan on black",
        debugtext     => "white on black",
        infotext      => "blue on black",
        blink         => "blue on black blink",
        title         => "yellow on black",
        statcolor     => "green on black",
        sockcolor     => "cyan on black",
        ncolor        => "white on black",
        st_frames     => "bright cyan on black",
        st_values     => "bright yellow on black",
        stderr_bullet => "bright white on red",
        stderr_text   => "bright yellow on black",
        err_input     => "bright white on red",
        help          => "white on black",
        help_cmd      => "bright white on black"
    );
    $vt->create_window(
        Window_Name  => "Nemesis Console",
        History_Size => 300,
        Common_Input => 1,
        Status       => {
            0 => {
                format => "\0(warn)" . "%8.8s",
                fields => [qw( time )]
            },
            1 => {
                format => "%s",
                fields => [qw( name )]
            },
        },

        Buffer_Size  => 1000,
        History_Size => 5000,
        Tab_Complete => sub() {
            my $left  = shift;
            my $right = shift;
            my @Res   = ();
            foreach my $current (
                $Init->getModuleLoader()->export_public_methods() )
            {
                push( @Res, $current . " " ) if ( $current =~ /^$left/i );
            }
            my %uniq;
            return sort grep { !$uniq{$_}++ } @Res;
        },

        #   Input_Prompt => "\$" ,
        Title => "Nemesis Framework Command Line"
    );

    $self->{'vt'} = $vt;
    return $self->{'vt'};
}

sub premutate {

# -----------------------------------------------------------------------------
    my $str = shift;
    my $re  = '\A';
    for ( 0 .. length $str ) {
        $re .= '(?:' . substr $str, $_, 1;
    }
    for ( 0 .. length $str ) {
        $re .= ')?';
    }
    return qr/$re/i;
}

sub get_prompt_out {
    my $self = shift;

    #return "\|";
    if ( exists( $self->{'vt'} ) ) {

        return
              "\0(warn)Nemesis\0(logo)\@\0(warntext)"
            . $Init->getSession()->getName()
            . "\0(blink)>#";    #For now, we have to change Term::ReadLine

    }
    else {

        return
              colored( "Nemesis", "green on_black" )
            . colored( "\@",                           "white on_black" )
            . colored( $Init->getSession()->getName(), "cyan on_black" )
            . colored( ">",                            "white on_black" )
            . colored( "# ", "blue on_black blink" );
    }
}

sub print_ascii {
    my $self      = shift;
    my $FILE      = $_[0];
    my $COLOR     = $_[1];
    my $REAL_FILE = $Init->getEnv()->{'ProgramPath'} . "/" . $FILE;
    open( my $fh, "<" . $REAL_FILE ) or croak("Can't open $REAL_FILE");
    while ( my $line = <$fh> ) {
        print colored( $line, $COLOR );
    }
    close $fh;
}

sub print_ascii_fh {
    my $self  = shift;
    my $FH    = $_[0];
    my $COLOR = $_[1];
    if ( exists( $self->{'vt'} ) ) {
        while ( my $line = <$FH> ) {

            $self->{'vt'}
                ->print( $self->{'vt'}->current_window(), "\0($COLOR)$line" );
        }
    }
    else {
        while ( my $line = <$FH> ) {
            print colored( $line, $COLOR );

            #  print "\0($COLOR)$line";
        }
    }
    return $OUT;
}

sub set_public_methods() {
    my $self = shift;
    $self->{'PUBLIC_METHOD'} = @_;
}

sub print_alert() {
    my $self = shift;
    my $caller=caller();
    if ( exists( $self->{'vt'} ) ) {
        $self->{'vt'}->print( $self->{'vt'}->current_window(),
            "\0(squareb)[\0(warn)Warn\0(squareb)]\t\0(warntext)"
                . join( " ", @_ ) );
    }
    else {
        print colored( "[",    "magenta on_black bold" )
            . colored( "Warn", "green on_black bold" )
            . colored( "]\t",  "magenta on_black bold" )
          .  colored( "[",    "magenta on_black bold" )
           . colored( $caller, "green on_black bold" )
            . colored( "]",  "magenta on_black bold" )
            . colored( $_[0],  "cyan on_black" ) . "\n";

    }

}

sub print_verbose() {
    my $self = shift;
    my $text = $_[0];
    if ( $self->{'verbose'} == 1 ) {

        # print "[! Nemesis Verbose !]\t" . $text . "\n";
    }
}

sub debug() {
    my $self   = shift;
    my $caller = caller();

    if ( exists( $self->{'debug'} )
        and $self->{'debug'} == 1 )
    {

        if ( exists( $self->{'vt'} ) ) {
            if ( defined($caller) ) {
                $self->{'vt'}->print( $self->{'vt'}->current_window(),
                          "\0(squareb) -> \0(warntext) "
                        . $caller
                        . " \0(squareb)<- "
                        . "\0(squareb)(\0(warn)"
                        . $Init->getEnv()->time_seconds()
                        . "\0(squareb)) \0(squareb)[\0(logo)Debug\0(squareb)]\0(debugtext) "
                        . $_[0] );

            }
            else {
                $self->{'vt'}->print( $self->{'vt'}->current_window(),
                          "\0(squareb)(\0(warn)"
                        . $Init->getEnv()->time_seconds()
                        . "\0(squareb)) \0(squareb)[\0(logo)Debug\0(squareb)] \0(debugtext) "
                        . $_[0] );

            }
        }
        else {

            print colored( " (", "magenta on_black bold" )
                . colored( $Init->getEnv()->time_seconds(),
                "bold on_black green" )
                . colored( ")", "magenta on_black bold" );
            print colored( " ->",   "magenta on_black bold" )
                . colored( $caller, "cyan on_black bold" )
                . colored( "<- ",   "magenta on_black bold" )
                if ($caller);
            print colored( " [",    "magenta on_black bold" )
                . colored( "Debug", "red on_black bold" )
                . colored( "] ",    "magenta on_black bold" )

                . colored( $_[0], "white on_black bold" ) . "\n";
        }

    }

}

sub print_info() {
    my $self = shift;
    my $caller= caller();
    if ( exists( $self->{'vt'} ) ) {
        $self->{'vt'}->print( $self->{'vt'}->current_window(),
                  "\0(squareb)[\0(warn)**\0(squareb)] \0(squareb)(\0(warn)"
                . $Init->getEnv()->time_seconds()
                . "\0(squareb))\0(infotext) "
                . join( " ", @_ ) );
    }
    else {
        print colored( "[",  "magenta on_black bold" )
            . colored( "**", "green on_black bold" )
            . colored( "]",  "magenta on_black bold" )
            .  colored( "[",    "magenta on_black bold" )
           . colored( $caller, "green on_black bold" )
            . colored( "]",  "magenta on_black bold" )
            . colored( " (", "magenta on_black bold" )
            . colored( $Init->getEnv()->time_seconds(), "bold on_black cyan" )
            . colored( ") ",  "magenta on_black bold" )
            . colored( $_[0], "blue on_black bold" ) . "\n";
    }
}

sub info() {
    my $self = shift;
    $self->print_info(@_);
}

sub error() {
    my $self = shift;
    $self->print_error(@_);
}

sub alert() {
    my $self = shift;
    $self->print_alert(@_);
}

sub tabbed() {
    my $self = shift;
    $self->print_tabbed(@_);
}

sub print_error() {
    my $self = shift;
    my $caller=caller();
    if ( exists( $self->{'vt'} ) ) {
        $self->{'vt'}->print( $self->{'vt'}->current_window(),
                  "\0(squareb)[\0(logo)Err\0(squareb)] \0(squareb)(\0(warn)"
                . $Init->getEnv()->time_seconds()
                . "\0(squareb))\0(warntext) "
                . join( " ", @_ ) );

    }
    else {
        print colored( "[",   "magenta on_black bold" )
            . colored( "Err", "red on_black bold blink" )
            . colored( "]",   "magenta on_black bold" )
            .  colored( "[",    "magenta on_black bold" )
           . colored( $caller, "green on_black bold" )
            . colored( "]",  "magenta on_black bold" )
            . colored( " (",  "magenta on_black bold" )
            . colored( $Init->getEnv()->time_seconds(), "bold on_black red" )
            . colored( ") ",  "magenta on_black bold" )
            . colored( $_[0], "cyan on_black" ) . "\n";
    }
}

sub print_tabbed {
    my $self = shift;

    $num = $_[ scalar(@_) ] || 1;

    if ( exists( $self->{'vt'} ) ) {
        $self->{'vt'}->print( $self->{'vt'}->current_window(),
            "\0(warn)" . ( "\t" x $num ) . "~> \0(infotext)" . $_[0] );
    }
    else {

        print( colored( ( "\t" x $num ) . "~> ", "green on_black bold" ),
            colored( $_[0], "blue on_black bold" ), "\n" );
    }
}

sub print_title {
    my $self = shift;
    my ($msg) = @_;
    if ( exists( $self->{'vt'} ) ) {
        $self->{'vt'}->print( $self->{'vt'}->current_window(),
            "\n\0(title)" . $msg . "\n" . ( "=" x length($msg) ) . "\n" );
    }
    else {
        printf "\n" . colored( $msg, "yellow on_black bold" ) . "\n";
        printf colored( "=" x length($msg), "white on_yellow" );
        printf "\n\n";
    }
}

sub process_status {
    my $self    = shift;
    my $Process = $_[0];
    $self->print_info( $Process->get_var("code") );
    if ( $Process->is_running() ) {
        my $pid = $Process->get_pid();
        if ( !$pid ) {
            $pid = "n/a";
        }
        $self->print_tabbed( "PID:\t " . $pid, 1 );
        if ( $Process->get_var('file') ) {
            $self->print_tabbed(
                "Output (STDOUT):\t " . $Process->get_var('file'), 1 );
        }
        if ( $Process->get_var('file_log') ) {
            $self->print_tabbed(
                "Output (Log):\t " . $Process->get_var('file_log'), 1 );
        }
        if ( $Process->is_running() ) {
            $self->print_tabbed( "RUNNING", 1 );
        }
    }
    else {
        $self->print_tabbed( "NOT RUNNING", 1 );
    }
}

sub exec() {
    my $self    = shift;
    my $command = $_[0];
    my @output;
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
    my $cwd = $Init->getSession()->{'CONF'}->{'VARS'}->{'SESSION_PATH'};
    open( my $handle, "cd $cwd;$final  2>&1 |" )
        or croak "Failed to open pipeline $!";
    while (<$handle>) {
        push( @output, $_ );
    }
    close($handle);

    #@output = `cd $cwd;$final`;
    chomp(@output);
    return @output;
}

sub verbose() {
    my $self = shift;
    $self->print_info( "Verbose mode " . $_[0] );
    $self->{'verbose'} = $_[0];
}

sub set_debug() {
    my $self = shift;
    $self->print_info( "Debug mode " . $_[0] );
    $self->{'debug'} = $_[0];
}

sub debug_dumper() {
    my $self = shift;
    my $Arg  = $_[0];

    # my $LogFile=$_[1] if($_[1]);
    $self->debug( Dumper($Arg) );
    ##  if(defined($LogFile)){
    #     open my $Log, ">".$LogFile;
    #    print $Log Dumper($Arg);
    ##    close $Log;
    #}
}

sub unici {
    shift;
    my @unici = ();
    my %visti = ();
    foreach my $elemento (@_) {

        #   $elemento =~ s/\/+/\//g;
        next if $visti{$elemento}++;
        push @unici, $elemento;
    }
    return @unici;
}

sub sanitize {
    my @unici = ();
    foreach my $elemento (@_) {
        next if $elemento eq "" or $elemento eq " ";
        push @unici, $elemento;
    }
    return @unici;
}

sub generate_command() {
    my $self    = shift;
    my $command = $_[0];
    my $env     = $Init->getEnv();
    my @path    = $env->path();
    if ( $command =~ /\s+/ ) {
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
        foreach my $p (@path) {

            $pp = $p;
            if ( -e "$p/$command" && $command !~ /\// )
            { #serve per ritrovare il programma di lancio e aggiungergli la path assoluta davanti
                if ( $pp =~ /\/$/ && $command =~ /^\// ) {
                    chop($pp);
                }
                $command = $pp . '/' . $command;
                last;
            }
        }
    }
    return $command;
}
1;

__END__
