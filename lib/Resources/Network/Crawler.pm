package  Resources::Network::Crawler;

#use Moose;
use Nemesis::BaseRes -base;
use Carp::Always;
has 'Proxy';
has 'Result'    => sub { [] };
has 'FieldName' => sub {'q'};
has 'SearchURL' => sub {"http://www.google.com"};
has 'PageRegex' => sub {'start'};
has 'Pages'     => sub { [] };
has 'UA'        => sub {'Windows IE 6'};
has 'Deep'      => sub {2};
has 'MechanizeRequest';
has 'searchURLS' => sub {

    [
    {   FieldName => 'text',
            SearchURL => 'http://www.yandex.ru/',
            PageRegex => '\?p\=',
            Deep      => 2
        },
{   FieldName => 'p',
            SearchURL => 'http://www.yahoo.com/',
            PageRegex => '&b\=',
            Deep      => 2
        },
{   FieldName => 'q',
            SearchURL => 'http://www.bing.com/',
            PageRegex => 'first',
            Deep      => 2
        },
      {   FieldName => 'q',
            SearchURL => 'http://www.google.com',
            PageRegex => 'start',
            Deep      => 2
        }
    ];
};

use WWW::Mechanize;
use Regexp::Common qw /URI/;

sub search() {
    my $self   = shift;
    my $String = shift;
    foreach my $Search ( @{ $self->searchURLS } ) {
        my $Crawl = $self->Init->ml->atom("Crawler");
        $Crawl->FieldName( $Search->{FieldName} );
        $Crawl->SearchURL( $Search->{SearchURL} );
        $Crawl->PageRegex( $Search->{PageRegex} );
        $Crawl->Deep( $Search->{Deep} );
        $Crawl->get($String);
        push(@{$self->{Result}},@{$Crawl->{Result}});
    }
}

sub get() {
    my $self   = shift;
    my $String = shift;
    my $mech   = WWW::Mechanize->new();
    $mech->agent_alias('Windows IE 6');
    $mech->get( $self->SearchURL );
    $mech->submit_form( fields => { $self->FieldName => $String } );
    $self->MechanizeRequest($mech);
    $self->getLinkFromPage();

    for ( my $i = 1; $i <= $self->Deep; $i++ ) {
        $self->fetchNext;
    }
    return $self;
}

sub getLinkFromPage() {
    my $self       = shift;
    my $mech       = $self->MechanizeRequest;
    my @URLS       = $self->urlclean( $mech->links );
    my @ActualURLS = @{ $self->Result };
    push( @{ $self->Result }, @URLS );
    $self->sugar;

}

sub stripLinks() {
    my $self = shift;
    return map { push @_, &links($_); } @{ $self->Result };
}

sub links() {
    my @list;
    my $link = $_[0];
    my $host = $_[0];
    my $hdir = $_[0];
    $hdir =~ s/(.*)\/[^\/]*$/$1/;
    $host =~ s/([-a-zA-Z0-9\.]+)\/.*/$1/;
    $host .= "/";
    $link .= "/";
    $hdir .= "/";
    $host =~ s/\/\//\//g;
    $hdir =~ s/\/\//\//g;
    $link =~ s/\/\//\//g;
    push( @list, $link, $host, $hdir );
    return @list;
}

sub urlclean() {
    my $self = shift;
    my @Urls = @_;

    my @Correct;
    my $r = $self->PageRegex;
    foreach my $url (@Urls) {
        if ( $url->url =~ /($RE{URI}{HTTP})/ ) {
            push( @Correct, $1 );
        }

        if ( $url->url =~ /$r/ ) {
            $url->base( $self->SearchURL );
            push( @{ $self->Pages }, $url->url_abs );
        }

    }
    @{ $self->Pages } = $self->Init->getIO()->unici( @{ $self->Pages } );
    return @Correct;
}

sub sugar() {
    my $self = shift;

    $self->Init->getIO()
        ->print_info( "Found a total of "
            . scalar( @{ $self->Result } )
            . " links from "
            . $self->SearchURL );
    $self->Init->getIO()->print_tabbed( join( "\t", @{ $self->Result } ), 2 );
    $self->Init->getIO()
        ->print_info( "We get also "
            . scalar( @{ $self->Pages } )
            . " pages to crawl for more" );
    $self->Init->getIO()->print_tabbed( join( "\t", @{ $self->Pages } ), 2 );

}

sub fetchNext() {
    my $self = shift;
    my $mech = WWW::Mechanize->new();
    $mech->agent_alias('Windows IE 6');
    my $Page = shift @{ $self->Pages };
    $mech->get($Page);
    $self->getLinkFromPage($mech);
}

1;
