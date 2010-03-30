package Net::Twitter::Stream;
use strict;
use warnings;
use IO::Socket;
use MIME::Base64;
use JSON;

our $VERSION = '0.23';
1;

=head1 NAME

Using Twitter's streaming api.

=head1 SYNOPSIS

  use Net::Twitter::Stream;

  Net::Twitter::Stream->new ( user => $username, pass => $password, callback => \&got_tweet,
                              track => 'perl,tinychat,emacs',
                              follow => '27712481,14252288,972651,679303,18703227,3839,27712481' );

     sub got_tweet {
	 my $tweet = shift;
	 print "By: $tweet->{user}{screen_name}\n";
	 print "Message: $tweet->{text}\n";
     }      

=head1 DESCRIPTION

The Streaming verson of the Twitter API allows near-realtime access to 
various subsets of Twitter public statuses.

Recent update: Track and follow are now merged into a single api call.
/1/status/filter.json now allows a single connection go listen for keywords
and follow a list of users.

HTTP Basic authentication is supported (no OAuth yet) so you will need a twitter
account to connect.

JSON format is only supported. Twitter may depreciate XML.

Options 
  user, pass: required, twitter account user/password
  callback: required, a subroutine called on each received tweet
  

perl@redmond5.com
@martinredmond

=cut


sub new {
  my $class = shift;
  my %args = @_;
  die "Usage: Net::Twitter::Stream->new ( user => 'user', pass => 'pass', callback => \&got_tweet_cb )" unless
    $args{user} && $args{pass} && $args{callback};
  my $self = bless {};
  $self->{user} = $args{user};
  $self->{pass} = $args{pass};
  $self->{got_tweet} = $args{callback};
  
  my $content = "follow=$args{follow}" if $args{follow};
  $content = "track=$args{track}" if $args{track};
  $content = "follow=$args{follow}&track=$args{track}\r\n" if $args{track} && $args{follow};
  
  my $auth = encode_base64 ( "$args{user}:$args{pass}" );
  chomp $auth;
  
  my $cl = length $content;
  my $req = <<EOF;
POST /1/statuses/filter.json HTTP/1.1\r
Authorization: Basic $auth\r
Host: stream.twitter.com\r
User-Agent: net-twitter-stream/0.1\r
Content-Type: application/x-www-form-urlencoded\r
Content-Length: $cl\r
\r
EOF
  
  my $sock = IO::Socket::INET->new ( PeerAddr => 'stream.twitter.com:80' );
  $sock->print ( "$req$content" );
  while ( my $l = $sock->getline ) {
    last if $l =~ /^\s*$/;
  }
  while ( my $l = $sock->getline ) {
    eval { 
      my $o = from_json ( $l );
      $self->{got_tweet} ( $o, $l );
    };
  }
}


