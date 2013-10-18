package Nemesis::Interfaces;
use warnings;
use Net::Ping;
use vars qw($VERSION);
$VERSION = '0.01';
use Socket;
use Carp qw( croak );
our $Init;

sub new {
    my $package = shift;
    bless( {}, $package );
    %{$package} = @_;
    croak 'No init' if !exists( $package->{'Init'} );
    $Init = $package->{'Init'};
    my %tmp;
    %{ $package->{'devices'} } = %tmp;
    $package->scan_avaible_devices();
    return $package;
}

sub scan_avaible_devices() {

#   function: scan_avaible_devices
#   @params:none
#   @return:none
#   Cerca le interfacce di rete collegate al computer tramite la variabile d'ambiente acquisita dall'altro modulo
    my $self = shift;
    my $IO   = $Init->getIO();
    my %tmp;
    my $counter;
    my @output;
    $self->read_interface("/proc/net/dev");
    $self->read_interface("/proc/net/wireless");

    foreach my $dev ( keys %{ $self->{'devices'} } ) {
        $self->parse_config( "ifconfig", $dev );
        if ( exists( $self->{'devices'}->{$dev}->{'WIRELESS'} )
            && $self->{'devices'}->{$dev}->{'WIRELESS'} == 1 )
        {
            $self->wifi_enum($dev);
            $self->parse_config( "iwconfig", $dev );
        }
    }

    #  $Init->io->debug_dumper( \$self );

    #Locating default gateway-
    @output = $IO->exec("ip route");
    foreach my $o (@output) {
        if ( $o =~ /default/ ) {
            my @res = split( / /, $o );
            $self->{'GATEWAY'} = $res[2];
        }
    }
}

sub wifi_scan() {
    my $self = shift;
    foreach my $dev ( keys %{ $self->{'devices'} } ) {
        $self->parse_config( "ifconfig", $dev );
        if ( exists( $self->{'devices'}->{$dev}->{'WIRELESS'} )
            && $self->{'devices'}->{$dev}->{'WIRELESS'} == 1 )
        {
            $self->wifi_enum($dev);
            $self->parse_config( "iwconfig", $dev );
        }
    }
}

sub info_device() {
    my $self   = shift;
    my $device = $_[0];
    my $IO     = $Init->getIO();
    if ( !$device ) {
        return;
    }
    $IO->print_info( "Device: " . $device );
    if ( exists( $self->{'devices'}->{$device}->{'IPV4_ADDRESS'} ) ) {
        $IO->print_tabbed( "IPv4:\t"
                . $self->{'devices'}->{$device}->{'IPV4_ADDRESS'}
                . "\t" );
    }
    if ( exists( $self->{'devices'}->{$device}->{'IPV6_ADDRESS'} ) ) {
        $IO->print_tabbed( "IPv6:\t"
                . $self->{'devices'}->{$device}->{'IPV6_ADDRESS'}
                . "\t" );
    }
    if ( exists( $self->{'devices'}->{$device}->{'WIRELESS'} )
        and $self->{'devices'}->{$device}->{'WIRELESS'} == 1 )
    {
        $IO->info( $device . " is a wireless device!" );

        #$IO->debug_dumper( \$self->{'devices'} );
        if ( exists( $self->{'devices'}->{$device}->{'AP'} ) ) {
            $IO->print_verbose(
                $device . " ap: " . $self->{'devices'}->{$device}->{'AP'} );
        }
        if ( exists( $self->{'devices'}->{$device}->{'ESSID'} ) ) {
            $IO->print_verbose( $device
                    . " essid: "
                    . $self->{'devices'}->{$device}->{'ESSID'} );
        }
    }
}

sub print_devices() {
    my $self   = shift;
    my $output = $Init->getIO();
    $output->print_verbose("Printing devices...");
    foreach my $dev ( keys %{ $self->{'devices'} } ) {
        $self->info_device($dev);
    }
    $output->print_info( "Local gateway: " . $self->{'GATEWAY'} )
        if exists( $self->{'GATEWAY'} );
}

sub connected() {
    my $self     = shift;
    my $output   = $Init->getIO();
    my $conn     = 0;
    my $internet = 0;
    foreach my $dev ( keys %{ $self->{'devices'} } ) {
        if ( $self->{'devices'}->{$dev}->{'IPV4_ADDRESS'} ne "" ) {
            $conn = 1;
            $output->print_info("Device $dev appears to be connected.");
            my $conn = $self->check_internet($dev);
            if ( $conn == 0 ) {
                $output->print_info(
                    "No internet connection :(, but don't worry about that.");
            }
            else {
                $internet = 1;
                $output->print_info("Connection found");
            }
        }
    }
    return $conn, $internet;
}

sub connected_devices() {
    my $self     = shift;
    my $conn     = 0;
    my $internet = 0;
    my @int;
    foreach my $dev ( keys %{ $self->{'devices'} } ) {
        push( @int, $dev );
    }
    return @int;
}

sub read_interface() {
    my $self = shift;
    my $file = $_[0];
    open FILE, "<" . $file;
    my @CONTENT = <FILE>;
    close FILE;
    foreach my $row (@CONTENT) {
        my @pieces = split( /\s/, $row );
        foreach my $piece (@pieces) {

            #my $next = $splitted + 1;
            if ( $piece =~ /\:/ ) {
                $piece =~ s/\://g;
                $tmp_dev = $piece;
                %{ $self->{'devices'}->{$tmp_dev} } = %tmp;
                if ( $file =~ /wireless/i ) {
                    $self->{'devices'}->{$tmp_dev}->{'WIRELESS'} = 1;
                }
            }
        }
    }
}

sub interfaces() {
    my $self = shift;
    my @Interfaces;
    @Interfaces = ( keys %{ $self->{'devices'} } );
    return @Interfaces;
}

sub getAPs {
    my $self = shift;
    my $Aps;

    my $device = shift || "all";

    if ( $device eq "all" ) {

        foreach my $dev ( keys %{ $self->{'devices'} } ) {
            if ( exists( $self->{'devices'}->{$dev}->{'WIRELESS'} )
                and $self->{'devices'}->{$dev}->{'WIRELESS'} eq 1 )
            {
                $Aps->{$dev} = $self->{'devices'}->{$dev}->{aps};
            }

        }

    }
    else {
        if ( exists( $self->{'devices'}->{$device} )
            and $self->{'devices'}->{$device}->{'WIRELESS'} eq 1 )
        {

            $Aps = $self->{'devices'}->{$device}->{aps};

            #  $Init->io->debug_dumper(\%Aps);

        }
    }

    return %$Aps;
}

sub ips() {
    my $self = shift;
    my @Ips;
    foreach my $dev ( keys %{ $self->{'devices'} } ) {
        push( @Ips, $self->{'devices'}->{$dev}->{'IPV4_ADDRESS'} )
            if exists( $self->{'devices'}->{$dev}->{'IPV4_ADDRESS'} )
            and $self->{'devices'}->{$dev}->{'IPV4_ADDRESS'} ne '127.0.0.1';
    }
    return @Ips;
}

sub check_internet() {
    my $self      = shift;
    my $interface = $_[0];
    my $alive     = 0;
    my $ping      = Net::Ping->new("tcp");
    $self->{'CONFIG'}->{'IO'}->print_info("Checking internet on $interface");
    $ping->bind( $self->{'devices'}->{$interface}->{'IPV4_ADDRESS'} )
        ;    # Specify source interface of pings
    $alive = 0 unless $ping->ping( "8.8.8.8", 5 );
    $Init->getIO->debug( "ALIVE:" . $alive );
    $ping->close();
    return $alive;
}

sub parse_config() {
    my $self   = shift;
    my $IO     = $Init->getIO();
    my $cmd    = $_[0];
    my $dev    = $_[1];
    my @OUTPUT = $IO->exec( $cmd . " " . $dev );
    foreach my $o (@OUTPUT) {
        if (    $o =~ /Point/i
            and $o =~ /((?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2})/i )
        {
            $self->{'devices'}->{$dev}->{'AP'} = $1;
        }
        my @pieces = split( /\s/, $o );
        $counter = 0;
        foreach my $piece (@pieces) {
            my $progressive = $counter + 1;
            if ( $piece eq "inet" ) {
                $self->{'devices'}->{$dev}->{'IPV4_ADDRESS'}
                    = $pieces[$progressive];
            }
            if ( $piece =~ /inet6/i ) {
                $self->{'devices'}->{$dev}->{'IPV6_ADDRESS'}
                    = $pieces[$progressive];
            }
            if ( $piece =~ /ESSID:(.*)/i ) {
                $self->{'devices'}->{$dev}->{'ESSID'} = $1;
                $self->{'devices'}->{$dev}->{'ESSID'} =~ s/\"|\'//g;
            }
            $counter++;
        }
    }
}

sub wifi_enum {
    my $self   = shift;
    my $Device = $_[0];
    my @Result = $Init->io->exec("iw dev $Device scan");
    my $current;
    foreach my $line (@Result) {
        if ( $line =~ /BSS\s+(.*)\(/ ) {

            $self->{'devices'}->{$Device}->{aps}->{$1} = {};
            $current = $1;
        }
        if ( $line =~ /SSID:\s+(.*)$/ ) {
            $self->{'devices'}->{$Device}->{aps}->{$current}->{"SSID"} = $1;
        }

        if ( $line =~ /signal:\s+(.*)$/ ) {
            $self->{'devices'}->{$Device}->{aps}->{$current}->{"signal"} = $1;

        }

        if ( $line =~ /WPS/ ) {
            $self->{'devices'}->{$Device}->{aps}->{$current}->{"security"}
                .= " WPS ";

        }
        if ( $line =~ /WEP/ ) {
            $self->{'devices'}->{$Device}->{aps}->{$current}->{"security"}
                .= " WEP ";

        }
        if ( $line =~ /WPA/ ) {
            $self->{'devices'}->{$Device}->{aps}->{$current}->{"security"}
                .= " WPA ";

        }
        if ( $line =~ /PSK/ ) {
            $self->{'devices'}->{$Device}->{aps}->{$current}->{"security"}
                .= " PSK ";

        }
        if ( $line =~ /TKIP/ ) {
            $self->{'devices'}->{$Device}->{aps}->{$current}->{"security"}
                .= " TKIP ";

        }

    }

}

1;
__END__
