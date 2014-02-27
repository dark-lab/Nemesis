package Resources::API::MSF::Session;
use Nemesis::BaseRes -base;
use Data::MessagePack;
use LWP;
use HTTP::Request;
use Resources::Util;
has 'MSFRPC';
has 'sessions' => sub {
    sub { {} }
};
has 'selected';
has 'data';
has 'cached_data';
has 'ReadPointer' => sub {0};

sub select {
    my $self    = shift;
    my $session = shift;
    $self->selected($session) if ( exists $sessions->{$session} );
    return $self;
}

sub list {
    my $self   = shift;
    my $answer = $self->MSFRPC->call('sessions.list');
    $self->sessions($answer);
    return keys %{$answer};
}

sub read {
    my $self = shift;
    return 0 if ( !$self->selected );
    my $answer = $self->MSFRPC->call( 'sessions.shell_read', $self->selected,
        $self->ReadPointer );
    $self->ReadPointer( $answer->{seq} );
    $self->data( $answer->{data} );
    $self->{cached_data} .= $answer->{data};
    return $self->data;
}

sub write {
    my $self = shift;
    my $data = shift;
    return 0 if ( !$self->selected );
    my $answer = $self->MSFRPC->call( 'sessions.shell_write', $self->selected,
        $data );
    return $answer->{"write_count"};
}

sub stop {
    my $self = shift;
    my $session = shift || $self->selected;
    return 0 if ( !$self->selected );
    my $answer = $self->MSFRPC->call( 'sessions.stop', $session );
    $answer->{result} eq "success"
        ? $self->ReadPointer(0) return 1
        : return 0;
}

1;
