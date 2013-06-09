package MiddleWare::shell;

use Nemesis::Inject;    #Requested to have your injection
use Try::Tiny;          #I really need that? :)

#@PUBLIC_FUNCTION will contain the function(s) that i want to need public to other modules (or by the cli) ?
my @PUBLIC_FUNCTIONS = qw(run);

#Nemesis module declaration
nemesis_module;

# run() will execute something in our machine

sub run() {
    my $self = shift;

    #Taking the args in @_
    my @ARGS = @_;

    #That's not really needed but it can be pleasant to have a shortcut
    my $IO = $Init->getIO();

#In $Init there are a lot of useful things, i'm taking here the interface to IO

    #joining all ARGS
    my $command = join( " ", @ARGS );

    try {
#Trying to execute my command (With IO it's safe to execute command because is also safe to your session directory)
        my @RESULT = $IO->exec($command);

        #Taking the result of command in @RESULT
        $IO->print_info( "\n" . join( "\n", @RESULT ) );
    }
    catch {
#Printing the error (also if it's difficult to believe that there will be one)
        $IO->print_error("Error executing command $command! $_");
    }

}

sub clear(){
    1;
}

1;
