package Nemesis::Packer;
use App::Packer::PAR;
#use strict;
use warnings;
use PAR::Packer ();


use PAR ();
use Module::ScanDeps ();;
	use Acme::EyeDrops;
	use Carp qw(croak);

	our $Init;



	sub new(){
		my $package = shift;
		bless( {}, $package );
		%{$package} = @_;
		$Init = $package->{'Init'};
		croak 'No init' if !exists( $package->{'Init'} );
		return $package;
	}

	sub pack(){
		my $self=shift;
		my ($What,$FileName)=@_;
		my $parpath=$Init->getEnv()->wherepath("par.pl");
		$Init->getIO()->debug("Chdir to $parpath");

		chdir($parpath);

		my @OPTS=($What);
		my @LOADED_PLUGINS=();

		foreach my $module ( sort( keys %{ $Init->getModuleLoader()->{'modules'} } ) )
		{
			push(@LOADED_PLUGINS,$Init->getModuleLoader()->{'Base'}->{'path'}."/".$module.".pm");
		}

		my %opt;
		$opt{P}= 1;
		$opt{o}= $FileName;
		#$opt{x} =1; #with this it still works!
		$opt{M} = \@LOADED_PLUGINS;

		#Bundle.export /home/mudler/_git/nemesis/cli.pl /home/mudler/nemesis_packed.pl
		App::Packer::PAR->new( frontend=> Module::ScanDeps, 
			backend=> PAR::Packer,
			backopts => \%opt,
			args	=> \@OPTS
		)->go;
		$Init->getSession()->safechdir;

	}


1;