package Net::Twitter::Stream::Track;
use base qw/Net::Twitter::Stream/;

1;

sub new {
  my $self = shift;
  my $un = shift;
  my $pw = shift;
  my $terms = shift;
  my $uri = "/track.json?track=$terms";
  $self->SUPER::new ( $un, $pw, $uri, @_ );
}



