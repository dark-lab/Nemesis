package Nemesis::Packer;
use App::Packer::PAR;

#use strict;
use warnings;
use PAR::Packer ();

use PAR              ();
use Module::ScanDeps ();
use Acme::EyeDrops;
use Carp qw(croak);

our $Init;

sub new() {
    my $package = shift;
    bless( {}, $package );
    %{$package} = @_;
    $Init = $package->{'Init'};
    croak 'No init' if !exists( $package->{'Init'} );
    return $package;
}

sub pack() {
    my $self = shift;
    my ( $What, $FileName ) = @_;
    my $parpath = $Init->getEnv()->wherepath("par.pl");
    $Init->getIO()->debug("Chdir to $parpath");

    chdir($parpath);

    my @OPTS           = ($What);
    my @LOADED_PLUGINS = map { my ($Name) = $_ =~m/([^\.|^\/]+)\.pm$/ ; $_= $Init->getModuleLoader()->_findLib($Name) ."/". $Name .".pm";  } $Init->getModuleLoader()->getLoadedLib();
    
   # my @CORE_MODULES= $Init->getModuleLoader()->_findLibsByCategory("Nemesis");
    #push(@LOADED_PLUGINS,@CORE_MODULES);
    foreach $m(@LOADED_PLUGINS){
        $Init->getIO()->debug("Core/Plugin/Resource to compress $m");
    }
    my %opt;
   # $opt{P} = 1;
    $opt{vvv}=1;
    $opt{o} = $FileName;
    #$opt{x} =1; #with this it still works!
    $opt{B}=1;
    $opt{M} = \@LOADED_PLUGINS;

    App::Packer::PAR->new(
        frontend => Module::ScanDeps,
        backend  => PAR::Packer,
        backopts => \%opt,
        args     => \@OPTS
    )->go;
    $Init->getSession()->safechdir;

}

1;
