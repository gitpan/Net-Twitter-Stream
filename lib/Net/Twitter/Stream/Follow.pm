package Net::Twitter::Stream::Follow;
use base qw/Net::Twitter::Stream/;

1;

sub new {
  my $self = shift;
  my $un = shift;
  my $pw = shift;
  my $ids = shift;
  my $uri = "/follow.json?follow=$ids";
  $self->SUPER::new ( $un, $pw, $uri, @_ );
}
