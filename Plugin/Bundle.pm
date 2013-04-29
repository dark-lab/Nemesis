package Plugin::Bundle;


use MooseX::Declare;

class Plugin::Bundle {
use PAR::Packer      ();
use PAR              ();
use Module::ScanDeps;

    use Nemesis::Inject;
    use namespace::autoclean;
    use App::Packer::PAR;
    our $VERSION = '0.1a';
    our $AUTHOR  = "mudler";
    our $MODULE  = "This is an interface to the Packer library";
    our $INFO    = "<www.dark-lab.net>";

    our @PUBLIC_FUNCTIONS = qw(export exportCli exportWrap);

    nemesis_module;

    method export( $What, $FileName ) {
        $self->Init->getIO()->print_info("Packing $What in $FileName");
            $self->pack( $What, $FileName );
            $self->Init->getIO()->print_info("Packed $What in $FileName");
        } 

    method exportCli($Where) {
        my $path = $self->Init->getEnv()->getPathBin();
            $self->export( $path . "/cli.pl", $Where );
            $self->Init->getIO()
            ->print_info("Export completated, $Where created");
        }
    method exportWrap($Where) {
    my $path = $self->Init->getEnv()->getPathBin();
        $self->export( $path . "/wrapper.pl", $Where );
        $self->Init->getIO()
        ->print_info("Export completated, $Where created");
    }



    method pack($What, $FileName) {
        my $parpath = $Init->getEnv()->wherepath("par.pl");
      #  $Init->getIO()->debug("Chdir to $parpath");
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


       $Init->getIO->print_info("Those are the library that i'm bundling in the unique file $FileName :");
                foreach my $Modules (@LOADED_PLUGINS){
                    $Init->getIO->print_tabbed($Modules,2);
                }

                #Hardcoded Moose required deps (ARGH MOOSEX DECLARE!)
                $Init->getIO->print_info("Acquiring Plugin dependencies... please wait");
                push( @LOADED_PLUGINS,
                    "MooseX/Declare/Syntax/RoleApplication.pm",
                    "MooseX/Declare/Syntax/EmptyBlockIfMissing.pm",
                    "MooseX/Declare/Syntax/InnerSyntaxHandling.pm",
                    "MooseX/Declare/StackItem.pm",
                    "MooseX/Declare/Context/Parameterized.pm",
                    "MooseX/Declare/Context/WithOptions.pm",
                    "MooseX/Declare/Context/Namespaced.pm",
                    "MooseX/Declare/Syntax/Keyword/With.pm",
                    "B/Hooks/EndOfScope/PP.pm",
                    "B/Hooks/EndOfScope/PP/FieldHash.pm",
                    "Parse/Method/Signatures/Param/Placeholder.pm",
                    "MooseX/LazyRequire/Meta/Attribute/Trait/LazyRequire.pm",
                    "Devel/Declare/Context/Simple.pm",
                    "MooseX/Declare/Syntax/Keyword/Class.pm",
                    "Parse/Method/Signatures/Param/Named.pm",
                    "MooseX/Declare/Syntax/MooseSetup.pm" ,
                    "MooseX/Declare/Syntax/Keyword/MethodModifier.pm" ,
                    "MooseX/Declare.pm",
                    "MooseX/Declare/Syntax/Keyword/Method.pm",
                    "MooseX/Declare/Context.pm",
                    "MooseX/Declare/Syntax/Keyword/Clean.pm",
                    "MooseX/Declare/Syntax/NamespaceHandling.pm",
                    "MooseX/Declare/Syntax/KeywordHandling.pm",
                    "MooseX/Declare/Syntax/MethodDeclaration.pm");
                #my @CORE_MODULES= $Init->getModuleLoader()->_findLibsByCategory("Nemesis");
                #push(@LOADED_PLUGINS,@CORE_MODULES);
         
                my %opt;
                #For Libpath add
                my @LIBPATH;
                push (@LIBPATH,$Init->getEnv->getPathBin);
                $opt{P}   = 1;           #Output perl
                #$opt{c}=1; #compiles-> MUST BE ENABLED ONLY WHEN LIBRARY ARE INSTALLED IN O.S.
                            #OTHERWISE NOTHING OF WHAT IS "USING" a PLUGIN WILL BE BUNDLED (e.g. MoooseX::Declare)
                #$opt{vvv} = 1;
                $opt{o}   = $FileName;
                #$opt{x} =1; #with this it still works!
                $opt{B} = 1;
                $opt{M} = \@LOADED_PLUGINS;
                # $opt{l} = \@LIBPATH;
                App::Packer::PAR->new(
                    frontend  => 'Module::ScanDeps', #NO BAREWORD cazz
                    backend   => 'PAR::Packer',
                    frontopts => \%opt,
                    backopts  => \%opt,
                    args      => \@OPTS
                )->go;
            
            }
        );

        return 1;
        # $Init->getSession()->safechdir;

    }

}

1;
