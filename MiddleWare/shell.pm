package MiddleWare::shell;
use Nemesis::BaseModule -base;

#@PUBLIC_FUNCTION will contain the function(s) that i want to need public to other modules (or by the cli) ?
our @PUBLIC_FUNCTIONS = qw(run);

sub run() {
    my $self = shift;

    #Taking the args in @_
    my @ARGS = @_;

    #That's not really needed but it can be pleasant to have a shortcut
    my $IO = $self->Init->getIO();

#In $Init there are a lot of useful things, i'm taking here the interface to IO

    #joining all ARGS
    my $command = join( " ", @ARGS );

    my @RESULT = $IO->exec($command);
    #Taking the result of command in @RESULT
    $IO->print_info( "\n" . join( "\n", @RESULT ) );

}

1;
