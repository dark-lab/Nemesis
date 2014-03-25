package Plugin::Bundle;

use Nemesis::BaseModule -base;

has 'What';
has 'Where';

our $VERSION          = '0.1a';
our $AUTHOR           = "mudler";
our $MODULE           = "This is an interface to the Packer library";
our $INFO             = "<www.dark-lab.net>";
our @PUBLIC_FUNCTIONS = qw(export exportCli exportWrap);

#use PAR::Packer ();
#use PAR         ();
use Module::ScanDeps;
use namespace::autoclean;

#use App::Packer::PAR;

use App::FatPacker;

#new App::FatPacker;
#  my @modules = split /\r?\n/, $self->trace(args => $args, use=> @Additional_modules);
# my @packlists = $self->packlists_containing(\@modules);

# my $base = catdir(cwd, 'fatlib');
# $self->packlists_to_tree($base, \@packlists);

# my $file = shift @$args;
# print $self->fatpack_file($file);

sub export( ) {
    my $self = shift;
    my $What;
    my $Filename;
    if ( scalar(@_) != 0 ) {
        $What     = shift;
        $Filename = shift;
        $self->What($What);
        $self->Where($Filename);
    }

    if ( !$self->What || !$self->Where ) {
        $self->Init->io->debug("You have not What and Where");
    }

    $self->Init->getIO()
        ->print_info( "Packing " . $self->What . "in " . $self->Where );
    $self->fatpack();

    #$self->pack(); commented due to par errors
    $self->Init->getIO()->print_info("Packing done");

}

sub exportCli() {
    my $self  = shift;
    my $Where = shift;
    if ( defined($Where) ) {
        $self->Where($Where);
    }
    my $path = $self->Init->getEnv()->getPathBin();
    $self->export( $path . "/nemesis", $self->Where );

}

sub exportWrap() {
    my $self  = shift;
    my $Where = shift;
    if ( defined($Where) ) {
        $self->Where($Where);
    }
    my $path = $self->Init->getEnv()->getPathBin();
    $self->export( $path . "/wrapper.pl", $self->Where );
}

sub fatpack() {
    my $self   = shift;
    my $Packer = new App::FatPacker;
    my @args   = ( $self->What, ">" . $self->Where );

    my @modules = split /\r?\n/,
        $self->trace( args => \@args, use => @Additional_modules );
    my @packlists = $self->packlists_containing( \@modules );

    my $base = catdir( $self->Init->env->getPathBin(), 'fatlib' );
    $self->packlists_to_tree( $base, \@packlists );

    my $file = shift @args;
    $self->write( $self->fatpack_file($file) );

}

sub write() {
    my $self = shift;
    open FILE, ">" . $self->Where();
    print FILE @_;
    close FILE;
}

sub pack {
    my $self = shift;
    my ( $What, $FileName ) = ( $self->What, $self->Where );
    my $parpath = $self->Init->getEnv()->wherepath("par.pl");

    #  $self->Init->getIO()->debug("Chdir to $parpath");
    $self->Init->getSession->safedir(
        $parpath,
        sub {
            my @OPTS = ($What);
            my @LOADED_PLUGINS = grep /./i, map {
                my ($Name) = $_ =~ m/([^\.|^\/]+)\.pm$/;
                if ($Name) {
                    $_ = $self->Init->getModuleLoader()->_findLib($Name) . "/"
                        . $Name . ".pm";
                }
                else {
                    $_ = ();
                }
            } $self->Init->getModuleLoader()->getLoadedLib();

            $self->Init->getIO->print_info(
                "Those are the library that i'm bundling in the unique file $FileName :"
            );
            foreach my $Modules (@LOADED_PLUGINS) {
                $self->Init->getIO->print_tabbed( $Modules, 2 );
            }

#my @Deps_Mods=Module::ScanDeps::scan_line($self->Init->getModuleLoader()->getLoadedLib());

            #  my $files=scan_deps(
            #   files   => [     @Deps_Mods, keys %INC],
            #      recurse => 1,
            #      compile => 1,

            #      );
            #  $self->Init->io->debug_dumper(\%INC);
            #  $self->Init->io->debug_dumper( \$files);
            # push(@Deps_Mods,keys %{$files});
            #Hardcoded Moose required deps (ARGH MOOSEX DECLARE!)
            $self->Init->getIO->print_info(
                "Acquiring Plugin dependencies... please wait");
            push( @LOADED_PLUGINS, keys %INC );

  #my @CORE_MODULES= $self->Init->getModuleLoader()->_findLibsByCategory("Nemesis");
  #push(@LOADED_PLUGINS,@CORE_MODULES);
            $self->Init->getIO->print_info("Filled with deps :");
            my @Additional_files;
            my $c = 0;
            foreach my $Modules (@LOADED_PLUGINS) {
                if ( $Modules !~ /\.txt|\.pm|\.pl/ ) {

                    # $self->Init->io->debug("Tooo bad for you $Modules");
                    push( @Additional_files, $Modules );
                    delete $LOADED_PLUGINS[$c];
                }

                $self->Init->getIO->print_tabbed( $Modules, 2 );
                $c++;
            }

            my %opt;

            #For Libpath add
            my @LIBPATH;
            push( @LIBPATH, $self->Init->getEnv->getPathBin );
            $opt{P} = 1;    #Output perl
              #$opt{c}=1; #compiles-> MUST BE ENABLED ONLY WHEN LIBRARY ARE INSTALLED IN O.S.
              #OTHERWISE NOTHING OF WHAT IS "USING" a PLUGIN WILL BE BUNDLED (e.g. MoooseX::Declare)
              #$opt{vvv} = 1;
            $opt{o} = $FileName;

            #$opt{x} =1; #with this it still works!
            $opt{B} = 1;
            $opt{a} = \@Additional_files;
            $opt{M} = \@LOADED_PLUGINS;
            $opt{l} = \@LIBPATH;

            # App::Packer::PAR->new(
            #      frontend  => 'Module::ScanDeps',    #NO BAREWORD cazz
            #     backend   => 'PAR::Packer',
            #     frontopts => \%opt,
            #      backopts  => \%opt,
            #     args      => \@OPTS
            #  )->go;

        }
    );

    return 1;

    # $self->Init->getSession()->safechdir;

}

1;
