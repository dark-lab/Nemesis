package Resources::Wireless::Reaver;

use Nemesis::BaseRes -base;

has 'SourceMac';
has 'TargetMac';
has 'essid';
has 'interface';
has 'channel';
has 'outputfile';
has 'sessionfile';
has 'auto';
has 'verbosity';
has 'fixed';
has 'process';

sub _generateCommand {
    my $self = shift;
    my $Command;
    $Command = "reaver";
    if ( defined( $self->SourceMac ) ) {
        $Command = _append( $Command, "-m", $self->SourceMac );
    }
    if ( defined( $self->TargetMac ) ) {
        $Command = _append( $Command, "-b", $self->TargetMac );
    }
    if ( defined( $self->essid ) ) {
        $Command = _append( $Command, "-e", $self->essid );
    }
    if ( defined( $self->interface ) ) {
        $Command = _append( $Command, "-i", $self->interface );
    }
    if ( defined( $self->channel ) ) {
        $Command = _append( $Command, "-c", $self->channel );
    }
    if ( defined( $self->outputfile ) ) {
        $Command = _append( $Command, "-o", $self->outputfile );
    }
    if ( defined( $self->sessionfile ) ) {
        $Command = _append( $Command, "-s", $self->sessionfile );
    }
    if ( defined( $self->auto ) ) {
        $Command = _append( $Command, "-a", '' );
    }
    if ( defined( $self->verbosity ) ) {
        $Command = _append( $Command, "-vv", '' );
    }
    if ( defined( $self->fixed ) ) {
        $Command = _append( $Command, "-f", '' );
    }
    return $Command;
}

sub _append() {
    $_[0] .= " ".$_[1] . " " . $_[2] . " ";
    return $_[0];
}




1;