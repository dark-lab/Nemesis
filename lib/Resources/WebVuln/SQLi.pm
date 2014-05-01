package Resources::WebVuln::LFI;
use Nemesis::BaseRes -base;
use Resources::Network::HTTPInterface;

has 'Bug';

sub test {
    my $self = shift;
    my @URLS = @_;
    my %Res;
    foreach my $url (@URLS) {
        $self->Init->getIO()->print_info("SQLinjection testing against $url");
        my $Test     = "http://" . $url . $self->Bug . "'";
        my $response = Resources::Network::HTTPInterface->new->get($Test);
        my $Content  = $response->{content};
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
