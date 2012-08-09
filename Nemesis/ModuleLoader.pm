package Nemesis::ModuleLoader;

use strict;

#external modules
use Data::Dump qw(dump);

my $options = {
    'port'      => { 'val' => 80,  'desc' => 'Webserver listening port' },
    'sslport'   => { 'val' => 443, 'desc' => 'Webserver SSL listening port' },
    'debug'     => { 'val' => 1,   'desc' => 'Debug mode' },
    'DNSPort'   => { 'val' => 53,  'desc' => 'Listen Name Server port' },
    'DNSEnable' => {
        'val'  => 1,
        'desc' => 'Enable DNS Server ( handle virtual request on modules )'
    },
    'DNSAnswerIp' =>
        { 'val' => "127.0.0.1", 'desc' => 'Resolve VHost to ip  )' },

};
my $base = {
    'path'    => 'Plugin',
    'pwd'     => './',
    'options' => $options
};

sub new {
    my $class = shift;
    my $self  = { 'Base' => $base };
    my (%Obj) = @_;
    %{ $self->{'core'} } = %Obj;
    die("IO and environment must be defined\n")
        if ( !defined( $self->{'core'}->{'IO'} )
        || !defined( $self->{'core'}->{'env'} ) );
    return bless $self, $class;
}

sub execute {
    my $self    = shift;
    my $module  = shift @_;
    my $command = shift @_;
    my $object  = "$self->{'Base'}->{'path'}::$module";
    eval( $object->$command(@_) );

}

sub export_public_methods() {
    my $self = shift;
    my @OUT;
    my @PUBLIC_FUNC;
    foreach my $module ( sort( keys %{ $self->{'modules'} } ) ) {

        eval {

            @PUBLIC_FUNC = ();
            @PUBLIC_FUNC =
                $self->{'modules'}->{$module}->export_public_methods();
            foreach my $method (@PUBLIC_FUNC) {
                $method = $module . "." . $method;

            }
            push( @OUT, @PUBLIC_FUNC );

        }

    }
    return @OUT;

}

sub listmodules {
    my $self = shift;
    my $IO   = $self->{'core'}->{'IO'};
    $IO->print_title("List of modules");
    foreach my $module ( sort( keys %{ $self->{'modules'} } ) ) {
        $IO->print_info("$module");
        $self->{'modules'}->{$module}->info()
            ; #so i can call also configure() and another function to display avaible settings!
    }

}

sub loadmodules {
    my $self = shift;
    my @modules;
    my $IO   = $self->{'core'}->{'IO'};
    my $path = $self->{'Base'}->{'pwd'} . $self->{'Base'}->{'path'};
    local *DIR;
    if ( !opendir( DIR, "$path" ) ) {
        return "[LOADMODULES] - (*) No such file or directory ($path)";
    }
    my @files = grep( !/^\.\.?$/, readdir(DIR) );
    closedir(DIR);

    my $modules;
    my $mods = 0;
    foreach my $f (@files) {
        my $base = $self->{'Base'}->{'path'} . "/" . $f;
        my ($name) = $f =~ m/([^\.]+)\.pm/;
        delete $INC{ $self->{'Base'}->{'path'} . "/" . $name };

        $IO->debug("Loading module: $base");
        my $result = do($base);

        if ($@) {
            $IO->print_info( 'Error: Loading module ($base):' . $@ );
            delete $INC{ $self->{'Base'}->{'path'} . "/" . $name };
            next;
        }
        if ( !$result ) {
            $IO->print_info("Error: module ($base) did not return true\n");
            next;
        }
        my $object = "$self->{'Base'}->{'path'}::$name";
        if ( eval { $modules->{$name} = $object->new( %{ $self->{'core'} }, ModuleLoader => $self ) }
            )
        {    #Verify object's creation
            $mods++;
        }
        else {
            $IO->print_error("Error: module ($base): $@");
        }

    }
    $IO->print_info("> $mods modules available.\n");
   # delete $self->{'modules'};
    $self->{'modules'} = $modules;
    return 1;
}

1;
