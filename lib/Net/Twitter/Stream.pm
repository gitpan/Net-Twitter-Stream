package Net::Twitter::Stream;
use MIME::Base64;
use IO::Socket;
use Danga::Socket;
use JSON;
use Data::Dumper;
use base ( 'Danga::Socket' );
use fields qw/headers_done uri got_tweet first_buf_debug last_buf_debug/;
our $VERSION = "0.1";

require Net::Twitter::Stream::Track;
require Net::Twitter::Stream::Follow;

1;

sub new {
  my $self = shift;
  $self = fields::new($self) unless ref $self;
  my $un = shift;
  my $pw = shift;
  my $uri = shift;
  $self->{got_tweet} = shift;
  my $auth = MIME::Base64::encode ( "$un:$pw" );
  $self->SUPER::new ( IO::Socket::INET->new ( "stream.twitter.com:80" ), @_ );

# send the http get request to twitter
  $self->write ( <<EOF );
GET $uri HTTP/1.0
Host: stream.twitter.com
Authorization: Basic $auth

EOF
  $self->watch_read(1);
  return $self;
}

sub i_close { 
  my $self = shift;
  warn "twitter i_close conection"; 
  warn $self->{first_buf_debug};
  warn $self->{last_buf_debug};
  exit;
}

sub close { 
  my $self = shift;
  warn "twitter close conection"; 
  warn $self->{first_buf_debug};
  warn $self->{last_buf_debug};
  exit; 
}

# read chunks of data from the server
sub event_read {
  my $self = shift;
  my $buf = $self->read ( 1024 * 8 );
  $self->i_close unless defined $buf;

  if ( $$buf =~ /^HTTP/ ) {
    $self->{headers_done} = 1;
    $self->{first_buf_debug} = $$buf;
    # dump anything else in this chunk
    return;
  }

  $self->{last_buf_debug} = $$buf;
  if ( $self->{headers_done} ) {
    # will be receiving json, one tweet per line
    foreach ( split /\n/, $$buf ) {
      $self->got_tweet ( $_ );
    }
  }
}

sub got_tweet {
  my ( $self, $js ) = @_;
  # sometimes there is a keep alive newline
  return if $js =~ /^\s*$/;

  my $obj;
  eval { $obj = from_json ( $js );};
  if ( $@ ) {
    warn "$@\n$js\n";
  } else {
    $self->{got_tweet} ( $obj );
  }
}

=head1 NAME

Using Twitter's streaming api.

=head1 SYNOPSIS
     use Net::Twitter::Stream;
     # Create "track" connection with a list of keywords.
     Net::Twitter::Stream::Track->new ( $username, $password,
		      'ffa,football,soccer,yankees,mashchat,mashable,tinychat,perl,memcached,nginx,javascript,talkabee,f136bc2d9f24,hackernews,reddit,clojure',
                      \&got_tweet_callback );

     # Create "follow" connection with a list of user ids.
     Net::Twitter::Stream::Follow->new ( $username, $password,
		       '27712481,14252288,972651,679303,18703227,3839,27712481',
                       \&got_tweet_callback );

     # Start listening
     Danga::Socket->EventLoop;

     sub got_tweet_callback {
	 my $tweet = shift;
	 print "By: $tweet->{user}{screen_name}\n";
	 print "Message: $tweet->{text}\n";
     }      

=head1 DESCRIPTION

Twitter recently allowed access to a streaming version of their api.
The api is currently under "alpha test" release, but hopfully it will
prove scalable and become the normal way to suck data from the
twitterverse.

Here is an example of how to use the api.  In particular the code connects
to a track and a follow stream.  Once connected the data flows from server
to client until something goes wrong.

Danga::Socket is required for event based network I/O and to manage
multiple connections.  I run this on a Mac and use Net::GrowlClient to
display tweets as they come in but that can be easily changed.

HTTP Basic authentication is supported so you will need a twitter
account to connect.

As far a I can tell twitter only allows one connection per IP.

perl@redmond5.com
@martinredmond

=cut

