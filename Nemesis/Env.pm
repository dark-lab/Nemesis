package Nemesis::Env;
use warnings;
use Storable;

sub new {
    my $package = shift;
    bless( {}, $package );
    $package->scan_env();
    if ( !-d $package->{'workspace'} ) {
        mkdir( $package->{'workspace'} );
    }
    if ( !-d $package->{'workspace'} . "/tmp" ) {
        mkdir( $package->{'workspace'} . "/tmp" );
    }
    return $package;
}

sub print_env() {
    my $self = shift;
    foreach my $key ( keys %ENV ) {
        print $key. " : " . $ENV{$key} . "\n";
    }
}

sub scan_env() {
    my $self = shift;
    my @path = split( /\:/, $ENV{'PATH'} );
    @{ $self->{'path'} } = @path;
    $self->{'workspace'} = $self->select_info("HOME") . "/.nemesis_data";

    #print %ENV;
}

sub select_info() {

    my $self = shift;
    my $var  = $_[0];

    foreach my $key ( keys %ENV ) {
        if ( $key eq $var ) {
            return $ENV{$var};
        }
    }

}

sub ipv4_forward {
    my $self = shift;
    if ( $_[0] eq "on" ) {
        open FILE, ">/proc/sys/net/ipv4/ip_forward";
        print FILE 1;
        close FILE;
    }
    elsif ( $_[0] eq "off" ) {
        open FILE, ">/proc/sys/net/ipv4/ip_forward";
        print FILE 0;
        close FILE;
    }

    open FILE, "</proc/sys/net/ipv4/ip_forward";
    my $res = <FILE>;
    return $res;
}

sub check_root() {

    my $result = 0;

    if ( `id` =~ /uid\=0/i ) {

        return 1;

    }

    return;

}

sub path() {
    my $self = shift;

    return
        @{ $self->{'path'}
        };    #acquisisce l'array precedentemente messo nella chiave "devices"
}

sub whereis {
    my $self       = shift;
    my $dependency = $_[0];
    if ( exists( $self->{'ENV'}->{$dependency} ) ) {
        return $self->{'ENV'}->{$dependency};
    }
    else {
        foreach my $path ( @{ $self->{'path'} } ) {
            @FILES = <$path/*>;
            foreach my $p (@FILES) {
                return $p if $p =~ /$dependency/i;
            }
        }
    }
    return;
}

sub path_for() {
    my $self = shift;
    my ( $i, $path ) = @_;
    $self->{'ENV'}->{$i} = $path;
}

sub workspace() {
    my $self = shift;
    return $self->{'workspace'};

}

sub tmp_dir() {
    my $self = shift;
    return $self->{'workspace'} . "/tmp";

}

sub time() {
    my $self     = shift;
    my @months   = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my ($second,     $minute,    $hour,
        $dayOfMonth, $month,     $yearOffset,
        $dayOfWeek,  $dayOfYear, $daylightSavings
    ) = localtime(time);
    if ( length($hour) == 1 )   { $hour   = "0" . $hour; }
    if ( length($minute) == 1 ) { $minute = "0" . $minute; }
    my $year = 1900 + $yearOffset;
    return
          $dayOfMonth . "."
        . $months[$month] . "."
        . $year . "_"
        . $hour . "-"
        . $minute;
}

sub save_state {
    my $pack = shift;
    Storable::nstore( $pack,
        File::Spec->catfile( $pack->{'workspace'} . "/env" ) );
}

sub restore_state {
    my $pack = shift;
    $pack = Storable::retrieve(
        File::Spec->catfile( $pack->{'workspace'} . "/env" ) );
}

sub time_seconds() {
    my $self     = shift;
    my @months   = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my ($second,     $minute,    $hour,
        $dayOfMonth, $month,     $yearOffset,
        $dayOfWeek,  $dayOfYear, $daylightSavings
    ) = localtime(CORE::time);
    my $year = 1900 + $yearOffset;
    if ( length($hour) == 1 )   { $hour   = "0" . $hour; }
    if ( length($minute) == 1 ) { $minute = "0" . $minute; }
    return "$hour:$minute:$second";
}

1;
__END__
