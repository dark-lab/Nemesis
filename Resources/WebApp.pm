package Resources::WebApp;

{
    use Nemesis::Inject;
    nemesis_mojo;

    use Mojolicious::Lite;

  get '/' => sub {
    my $self=shift;

    my $Scanner = $Init->getModuleLoader()->loadmodule("Scanner");
    my $meta = $Scanner->meta;

     my @Attr;
     for my $attr ( $meta->get_all_attributes ) {
      push(@Attr,$attr->name." DOC >".$attr->documentation);
     }

    for my $method ( $meta->get_all_methods ) {
            push(@Attr,$method->fully_qualified_name);

    }

    $self->render(text => "Hello <br>".join("<br>",@Attr));
  };

  # Route associating "/time" with template in DATA section
  get '/time' => 'clock';

  # RESTful web service with JSON and text representation
  get '/list/:offset' => sub {
    my $self    = shift;
    my $numbers = [0 .. $self->param('offset')];
    $self->respond_to(
      json => {json => $numbers},
      txt  => {text => join(',', @$numbers)}
    );
  };

  # Scrape information from remote sites
  post '/title' => sub {
    my $self = shift;
    my $url  = $self->param('url') || 'http://mojolicio.us';
    $self->render_text(
      $self->ua->get($url)->res->dom->html->head->title->text);
  };

  # WebSocket echo service
  websocket '/echo' => sub {
    my $self = shift;
    $self->on(message => sub {
      my ($self, $msg) = @_;
      $self->send("echo: $msg");
    });
  };
  


}


1;

__DATA__

@@ clock.html.ep
% use Time::Piece;
% my $now = localtime;
%
The time is <%= $now->hms %>.
