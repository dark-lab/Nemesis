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

    #    chdir($parpath);

    $Init->getSession->safedir(
        $parpath,
        sub {
            my @OPTS           = ($What);
            my @LOADED_PLUGINS = map {
                my ($Name) = $_ =~ m/([^\.|^\/]+)\.pm$/;
                $_ =
                      $Init->getModuleLoader()->_findLib($Name) . "/" 
                    . $Name . ".pm";
            } $Init->getModuleLoader()->getLoadedLib();

  #my @CORE_MODULES= $Init->getModuleLoader()->_findLibsByCategory("Nemesis");
  #push(@LOADED_PLUGINS,@CORE_MODULES);
            foreach $m (@LOADED_PLUGINS) {
                $Init->getIO()->debug("Adding $m to the bundle");
            }
            push(@LOADED_PLUGINS,"Parse::Method::Signatures","MooseX::Traits");
            my %opt;
 
            $opt{P} = 1; #Output perl
          #  $opt{c}=1; #compiles
            $opt{vvv} = 1;
            $opt{o}   = $FileName;

            #$opt{x} =1; #with this it still works!
           $opt{B}=1; #Bundling all won't work because of PAR, circular dependencies: need to remove "use" from main code (cli in this case)
          #But since we wouldn't pack cli but just the interface to framework, we wouldn't have this problem in the future
            $opt{M} = \@LOADED_PLUGINS;

            App::Packer::PAR->new(
                frontend => Module::ScanDeps,
                backend  => PAR::Packer,
                frontopts => \%opt,
                backopts => \%opt,
                args     => \@OPTS
            )->go;
        }
    );

    # $Init->getSession()->safechdir;

}

1;
