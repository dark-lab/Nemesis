package Resource::Connector;

use Moose;
use Alt::Crypt::RSA::BigInt;
use IO::Socket::INET;

has 'Node'         => ( is => "rw" );
has 'Channel'      => ( is => "rw" );
has 'Port'         => ( is => "rw", default => "49819" );
has 'Proto'        => ( is => "rw", default => "tcp" );
has 'PrivateKey'   => ( is => "rw" );
has 'PublicKey'    => ( is => "rw" );
has 'Password'     => ( is => "rw", default => "randompasshere" );
has 'Identity'     => ( is => "rw", default => "Nemesis Node" );
has 'Socket'       => ( is => "rw" );
has 'ChallengeKey' => ( is => "rw", default => "StaticPasswordHere" );
has 'Forking'      => ( is => "rw", default => 0 );

use Crypt::CBC;
$cipher = Crypt::CBC->new(
    -key    => 'my secret key',
    -cipher => 'Blowfish'
);

$ciphertext = $cipher->encrypt("This data is hush hush");
$plaintext  = $cipher->decrypt($ciphertext);

sub generate() {
    my $self = shift;
    if ( !$self->Password or !$self->Identity ) {
        $Init->io->error("You must set a password and an Identity first");
        return 0;
    }
    my $rsa = new Alt::Crypt::RSA::BigInt;
    my ( $Public, $Private ) = $rsa->keygen(
        Identity  => $self->Identity,
        Size      => 1024,
        Password  => $self->Password,
        Verbosity => 1,
    ) or ( $Init->io->error( $rsa->errstr() ) and return () );
    $self->PublicKey($Public);
    $self->PrivateKey($Private);
    $Init->io->debug( "PubKey : \n $Public", __PACKAGE__ );

}

sub encrypt()
{   #Take an outside public certs and encrypt for that destination the message
    my $self       = shift;
    my $Public     = shift;
    my $Message    = shift;
    my $rsa        = new Alt::Crypt::RSA::BigInt;
    my $Cyphertext = $rsa->encrypt(
        Message => $Message,
        Key     => $Public,
        Armour  => 1,
    ) || ( $Init->io->error( $rsa->errstr() ) and return () );

    $Init->io->debug( "PubKey : \n $Public",      __PACKAGE__ );
    $Init->io->debug( "Encrypted : \n $Message",  __PACKAGE__ );
    $Init->io->debug( "Decoded : \n $Cyphertext", __PACKAGE__ );

    return $Cyphertext;
}

sub decrypt() {
    my $self = shift;
    my $Cyphertext;
    my $rsa       = new Alt::Crypt::RSA::BigInt;
    my $plaintext = $rsa->decrypt(
        Cyphertext => $Cyphertext,
        Key        => $self->PrivateKey,
        Armour     => 1,
    ) || ( $Init->io->error( $rsa->errstr() ) and return () );
    $Init->io->debug( "Decoded : \n$plaintext", __PACKAGE__ );
    return $plaintext;
}

sub sign() {
    my $self    = shift;
    my $Message = shift;
    my $rsa     = new Alt::Crypt::RSA::BigInt;
    my $Signature =
        $rsa->sign( Message => $Message, Key => $self->PrivateKey )
        || ( $Init->io->error( $rsa->errstr() ) and return () );
    return $Signature;
}

sub verify() {
    my $self      = shift;
    my $Signature = shift;
    my $Message   = shift;
    my $PubKey;
    my $rsa    = new Alt::Crypt::RSA::BigInt;
    my $Verify = $rsa->verify(
        Message   => $Message,
        Signature => $Signature,
        Key       => $PubKey
    ) || ( $Init->io->error( $rsa->errstr() ) and return () );
    return $Verify;
}

sub connect() {
    my $self = shift;
    if ( $self->Socket ) {
        return $self->Socket;
    }
    my $socket = IO::Socket::INET->new(
        PeerAddr => $self->Node->ip,
        PeerPort => $self->Port,
        Proto    => $self->Proto,
        Timeout  => 3
        )
        || (
        $Init->io->error(
                  "Error connecting to "
                . $self->Node->ip . ":"
                . $self->Port . " ("
                . $self->Proto . ")"
        )
        and return ()
        );
    $self->Socket($socket);
    $Init->io->debug(
        "Connected to "
            . $self->Node->ip . ":"
            . $self->Port . " ("
            . $self->Proto . ")",
        __PACKAGE__
    );
    return $socket;
}

sub listen() {
    my $self = shift;
    if ( $self->Socket ) {
        return $self->Socket;
    }
    my $socket = IO::Socket::INET->new(
        Proto     => $self->Proto,    # protocol
        LocalPort => $self->Port,
        Reuse     => 1
        )
        || ( $Init->io->error( "Cannot bind to port " . $self->Port )
        and return () );
    $socket->listen();                # listen
    $socket->autoflush(1);            # To send response immediately
    $self->Socket($socket);
    return $self->Socket if ( $self->Forking == 0 );
    $self->receive();
}

sub receive() {

    my $self = shift;
    while ( $client = $self->Socket->accept() ) {    # receive a request
        $Init->io->debug( "Connected from: ",
            $client->peerhost(), __PACKAGE__ );
        print " Port: ", $client->peerport(), "\n";
        my $result;          # variable for Result
        while (<$addr>) {    # Read all messages from client
                             # (Assume all valid numbers)
            last if m/^end/gi;    # if message is 'end'
                                  # then exit loop
            print "Received: $_"; # Print received message
            print $addr $_;       # Send received message back
                                  # to verify
            $result += $_;        # Add value to result
        }
        chomp;                    # Remove the
        if (m/^end/gi) {          # You need this. Otherwise if
                                  # the client terminates abruptly
                                  # The server will encounter an
                                  # error when it sends the result back
                                  # and terminate
            my $send = "result=$result";    # Format result message
            print $addr "$send\n";          # send the result message
            print "Result: $send\n";        # Display sent message
        }
        print "Closed connection\n";        # Inform that connection
                                            # to client is closed
        close $addr;                        # close client
        print "At your service. Waiting...\n";

        # Wait again for next request
    }

}
