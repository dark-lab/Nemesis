package Resources::UI::Terminterface;
use Term::ReadLine;
use Resources::Logo;
use Nemesis::BaseRes -base;
our @PUBLIC_LIST=();
sub run() {
    my $self = shift;

    my $output = $self->Init->getIO();
    my $Init   = $self->Init;
    no strict;
    $output->print_ascii_fh( Resources::Logo::DATA, "red on_black bold" );
    $Init->{'Interfaces'}->print_devices();
    $Init->checkroot();
    $Init->ml()->loadmodules();

    #$Init->ml->execute_on_all("prepare");
    # Setting the terminal
    my $term_name = "Nemesis";
    my $nemesis_t = new Term::ReadLine($term_name);
    my $attribs   = $nemesis_t->Attribs;
    @PUBLIC_LIST = $Init->getModuleLoader->export_public_methods();
    $attribs->{completion_function} = sub { return @PUBLIC_LIST; };

    $Init->getSession()->wrap_history($nemesis_t);

    $Init->getIO()->print_info("Press CTRL+L to clear screen");

    # Main loop. This is inspired from the POD page of Term::Readline.
    while (
        defined( $_ = $nemesis_t->readline( $output->get_prompt_out() ) ) )
    {
        $Init->getIO()->parse_cli($_);
    }

}

1;
