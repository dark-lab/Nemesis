package Plugin::shell;

use Nemesis::Inject;
use TryCatch;

my @PUBLIC_FUNCTIONS=	qw(run);    #Public exported functions NECESSARY

nemesis_module;
sub run(){
	my $self=shift;
	my @ARGS=@_;
	my $IO=$Init->getIO();
	my $command=join(" ",@ARGS);
	
	
	
	try{
		my @RESULT=$IO->exec($command);
		$Init->getSession()->execute_save( "shell", "run", $command );
		$IO->print_info("\n".join("\n",@RESULT));
	} catch($error){
		$IO->print_error("Error executing command $command! $error");
	}
	
}

sub clear(){
	1;
}
1;
