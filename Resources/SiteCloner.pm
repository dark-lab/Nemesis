package Resources::SiteCloner;
{
    
    use Mojolicious::Lite;
    use Nemesis::Inject; #Esporta $Init nella webApp
    use Data::Dumper; #Esporta Dumper (per usarlo nei print)
 	use WWW::Mechanize; #Abilita l'uso di mechanizer
	nemesis_resource_mojo;

  get '/' => sub {
    my $self=shift;
    #Dalla documentazione di Mojolicious
     say Dumper $self->tx->req->content->headers->host; #$self->tx->req->content->headers->host contiene la richiesta dell'host remoto (ovvero che cosa ha digitato per raggiungerti)
     #Dalla documentazione di mojo : tx contiene i dati della trasmissione (indicazioni anche sul client)
     # facendo infatti say Dumper $self, vedrai tutto quello che ha da offrire
            $self->render(text => $self->ua->get("http://www.perl.org")); #NB: Sbagliato Il suo output è : Mojo::Transaction::HTTP=HASH( _AREA_MEMORIA )
            #Non è quello che ci aspettavamo, perchè? printa l'oggetto in modo stringa (come faresti in java con .AsString )
            #Mojo::Transaction (cercando su metacpan), ha il metodo res, che contiene la risposta e le sue parti, dunque:
            $self->render(text => $self->ua->get("http://www.perl.org")->res->body);  
  };

  get '/facebook' => sub {
    my $self    = shift;
		my $mech = WWW::Mechanize->new(); #Alloco un nuovo Mechanize
		$mech->agent_alias( 'Windows IE 6' ); #Setto l'agent del client
		$mech->get( "http://www.facebook.it" ); #Prendo il sito
		say $mech->res->content(); #$mech->res ritorna un HTTP::Response object, che ha un metodo content per visualizzare il contenuto della risposta http
		$self->render(text =>$mech->res->content() );
  };

  any '/a' => sub { #Esatto, gestisce anche tutto! :D
  	my $self=shift;
  	$self->render(text => $self->ua->get("http://".$self->tx->req->content->headers->host); #Questo in teoria dovrebbe fare il nostro giochetto.
  		 #Ma : la ua (UserAgent) di Mojo per quanto ne so, non automatizza il redirect in caso di HTTP Response Moved Permantently/Temporary per questo ti consiglio di usare 
  		 #Mech e quindi:
	my $mech = WWW::Mechanize->new();
	$mech->agent_alias( 'Windows IE 6' );
	$mech->get( "http://".$self->tx->req->content->headers->host );
	$self->render(text => $mech->res->content()); #ok, così va meglio dunque :)
  }

  

}


1;

