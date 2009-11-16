package Net::Twitter::Stream;
use strict;
use warnings;
use LWP::UserAgent;
our $VERSION = '0.2';
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

Twitter recently allowed access to a streaming version of their api.
The api is currently under "alpha test" release, but hopfully it will
prove scalable and become the normal way to suck data from the
twitterverse.

Recent update: Track and follow are now merged into a single api call.
/1/status/filter.json now allows a single connection go listen for keywords
and follow a list of users.

HTTP Basic authentication is supported (no OAuth yet) so you will need a twitter
account to connect.

Options 
  user, pass: required, twitter account user/password
  callback: required, a subroutine called on each received tweet
  format: optional, returned data format, json or xml, defaults to json

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
  my $format = 'json';
  $format = $args{format} if $args{format};

  my $content = "follow=$args{follow}" if $args{follow};
  $content = "track=$args{track}" if $args{track};
  $content = "follow=$args{follow}&track=$args{track}\r\n" if $args{track} && $args{follow};

  my $req = HTTP::Request->new ( 'POST', 
				 "http://$args{user}:$args{pass}\@stream.twitter.com/1/statuses/filter.$format",
				 [ 'Content-Type' => 'application/x-www-form-urlencoded' ],
				 $content );
  return $req if $args{getreq};

  LWP::UserAgent->new->request ( $req,
				 sub {
				     my ( $chunk, $res ) = @_;
				     $args{callback}($chunk, $res);
				 } );
}


