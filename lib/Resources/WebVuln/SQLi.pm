package Resources::WebVuln::SQLi;
use Nemesis::BaseRes -base;
use Resources::Network::HTTPInterface;

has 'Bug';

sub test {
    my $self = shift;
    my %Res;
    foreach my $url (@_) {
        my $Test = $url . $self->Bug . "'";
        $self->Init->getIO->debug("SQLinjection testing $Test");
        my $response = Resources::Network::HTTPInterface->new->get($Test);
        my $Content  = $response->{content};

        #$self->Init->getIO()->debug($Content);
        if ( $Content
            =~ m/You have an error in your SQL syntax|Query failed|SQL query failed/i
            )
        {
            $Res{$Test} = "mysql";
        }
        elsif ( $Content
            =~ m/ODBC SQL Server Driver|Unclosed quotation mark|Microsoft OLE DB Provider for/i
            )
        {
            $Res{$Test} = "msserver";
        }
        elsif ( $Content
            =~ m/Microsoft JET Database|ODBC Microsoft Access Driver/i )
        {
            $Res{$Test} = "access";
        }
    }
    return %Res;
}

1;
