package Plugin::Metasploit;
use warnings;
my $VERSION          = '0.1a';
my $AUTHOR           = "mudler";
my $INFO             = "<www.dark-lab.net>";
my @PUBLIC_FUNCTIONS = qw(configure check_installation start);

sub new {

 #Usually the new() and export_public_methods can be copyed from other plugins

    my $package = shift;
    bless( {}, $package );
    my (%Obj) = @_;
    %{ $package->{'core'} } = %Obj;

    #Here goes the required parameters to be passed

    die("IO and environment must be defined\n")
        if ( !defined( $package->{'core'}->{'IO'} )
        || !defined( $package->{'core'}->{'env'} ) );
    return $package;
}

sub export_public_methods() {
    my $self = shift;
    return @PUBLIC_FUNCTIONS;

}

sub start {
    my $self = shift;
    my $IO   = $self->{'core'}->{'IO'};
    my $env  = $self->{'core'}->{'env'};
    $IO->print_info("Metasploit module loaded.");

}

sub info {
    my $self = shift;

    my $IO  = $self->{'core'}->{'IO'};
    my $env = $self->{'core'}->{'env'};
    $IO->print_info(
        "->\tMetasploit framework utility module v$VERSION ~ $AUTHOR ~ $INFO"
    );
}

sub configure {
    my $self = shift;

    #postgre pc_hba.conf

}
sub clear(){
	return 1;}
sub test {
    my $self = shift;
    $self->{'core'}->{'IO'}
        ->print_info( "Test Received args:" . join( ' ', @_ ) );

}

sub check_installation {
    my $self      = shift;
    my $env       = $self->{'core'}->{'env'};
    my $IO        = $self->{'core'}->{'IO'};
    my $workspace = $env->workspace();
    $IO->print_info( "Workspace: " . $workspace );
}

1;
__END__
