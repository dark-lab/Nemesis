package MiddleWare::Jobs;
use Nemesis::BaseModule -base;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Metasploit Module";
our $INFO    = "<www.dark-lab.net>";

#Funzioni che fornisco.
our @PUBLIC_FUNCTIONS = qw(list kill detach result status  clear);  #NECESSARY

has 'Processes' => sub{[]};

sub prepare { my $self = shift; $self->import_jobs(); }

sub add {    #Not avaible from cli, but avaible among Plugins/MiddleWare
    my $self = shift;
    push( @{ $self->Processes }, $_[0] );
    return $self;
}

sub clear() {
    my $self = shift;
    $self->Init->io->info("cleaning not running and pending jobs");
    foreach my $Proc ( @{ $self->Processes } ) {

        $Proc->destroy() if ( !$Proc->is_running );

    }

}

sub list {
    my $self = shift;
    $self->Init->io->print_title("what are your modules?");
    foreach my $Job ( @{ $self->Processes } ) {
        $self->Init->io->process_status($Job);
    }
}

sub import_jobs() {
    my $self = shift;
    opendir( DIR, $self->Init->getEnv()->tmp_dir() )
        or $self->Init->io->error($!);
    while ( my $file = readdir(DIR) ) {
        next if $file eq ".." or $file eq ".";
        next if $file !~ /\.lock/;
        $file =~ s/\..*$//g;
        $self->Init->io->debug("checking $file");
        my $found = 0;
        foreach my $Proc ( @{ $self->Processes } ) {
            if ( $Proc->get_id eq $file ) {
                my $Process = $self->Init->ml->atom("Process");
                $Process->load($file);
                push( @{ $self->Processes }, $Process );
                $found = 1;
                last;
            }
        }
        if ( $found == 0 ) {
            my $Process = $self->Init->ml->loadmodule("Process");
            $Process->load($file);
            push( @{ $self->Processes }, $Process );
        }

    }
    closedir(DIR);
}

1;
