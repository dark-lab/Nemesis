package MiddleWare::Jobs;
use Nemesis::BaseModule -base;
use Resources::Util;

our $VERSION = '0.1a';
our $AUTHOR  = "mudler";
our $MODULE  = "Metasploit Module";
our $INFO    = "<www.dark-lab.net>";

#Funzioni che fornisco.
our @PUBLIC_FUNCTIONS
    = qw(list kill detach result status clear stopall);    #NECESSARY

has 'Processes' => sub { [] };

sub prepare { shift->import_jobs(); }

sub add {    #Not avaible from cli, but avaible among Plugins/MiddleWare
    my $self = shift;
    push( @{ $self->Processes }, @_ );
    return $self;
}

sub stopall {
    my $self = shift;
    $self->import_jobs();
    $self->Init->io->info("Stopping all jobs");
    $_->destroy() for ( @{ $self->Processes } );
}

sub clear() {
    my $self = shift;
    $self->import_jobs();
    $self->Init->io->info("cleaning not running and pending jobs");
    foreach my $Proc ( @{ $self->Processes } ) {
        $Proc->destroy() if ( !$Proc->is_running );
    }
}

sub list {
    my $self = shift;
    $self->Init->io->print_title("Jobs in execution");
    foreach my $Job ( @{ $self->Processes } ) {
        $self->Init->io->process_status($Job);
    }
}

sub tag() {
    my $self = shift;
    my $tag  = shift;
    foreach my $Job ( @{ $self->Processes } ) {
        return $Job if ( $Job->get_var("tag") eq $tag );
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
                push( @{ $self->Processes }, $Process )
                    if !&Resources::Util::match( $self->Processes, $Process );
                $found = 1;
                last;
            }
        }
        if ( $found == 0 ) {
            my $Process = $self->Init->ml->loadmodule("Process");
            $Process->load($file);
            push( @{ $self->Processes }, $Process )
                if !&Resources::Util::match( $self->Processes, $Process );
        }

    }
    closedir(DIR);
}

1;
