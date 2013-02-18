package Nemesis::Packer;
use App::Packer::PAR;

#use strict;
use warnings;
use PAR::Packer      ();
use PAR              ();
use Module::ScanDeps;
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


            push( @LOADED_PLUGINS,
                "MooseX/Declare/Syntax/Keyword/Class.pm","Parse/Method/Signatures/Param/Named.pm","MooseX/Declare/Syntax/MooseSetup.pm" ,"MooseX/Declare/Syntax/Keyword/MethodModifier.pm" ,"MooseX/Declare.pm","MooseX/Declare/Syntax/MethodDeclaration.pm");


            #my @CORE_MODULES= $Init->getModuleLoader()->_findLibsByCategory("Nemesis");
            #push(@LOADED_PLUGINS,@CORE_MODULES);

            $Init->getIO->print_info("Those are the library that i'm bundling with it :");
            foreach my $Modules (@LOADED_PLUGINS){
                $Init->getIO->print_tabbed($Modules,2);
            }

            my %opt;
            #For Libpath add
            my @LIBPATH;
            push (@LIBPATH,$Init->getEnv->getPathBin);
           $opt{P}   = 1;           #Output perl
            $opt{c}=1; #compiles-> MUST BE ENABLED ONLY WHEN LIBRARY ARE INSTALLED IN O.S.
                        #OTHERWISE NOTHING OF WHAT IS "USING" a PLUGIN WILL BE BUNDLED (e.g. MoooseX::Declare)
            $opt{vvv} = 1;
            $opt{o}   = $FileName;

            #$opt{x} =1; #with this it still works!
            $opt{B} = 1
                ;
             $opt{M} = \@LOADED_PLUGINS;
            # $opt{l} = \@LIBPATH;

            App::Packer::PAR->new(
                frontend  => Module::ScanDeps,
                backend   => PAR::Packer,
                frontopts => \%opt,
                backopts  => \%opt,
                args      => \@OPTS
            )->go;
        }
    );

    return 1;
    # $Init->getSession()->safechdir;

}

1;
