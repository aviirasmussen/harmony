#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
#
use Mojo::Base -strict, -signatures;
use Mojo::Message::Request;
use Mojo::IOLoop;
use Mojo::Log;
use Mojo::JSON qw(decode_json encode_json);
#
use Data::Dumper;
#
# tcp proxy server to relay json-rpc 2.0 from tcp to upstream HTTP server
# all messages should end with CTRL and/or LF
#
my %buffer;
my $PROXY_PORT  = 3210;
my $PROXY_IP    = '192.168.1.32';
my $AGENT_IP    = '192.168.1.32';
my $AGENT_PORT  = 8080;
#
my $log = Mojo::Log->new;
my $id  = Mojo::IOLoop->server({address => $PROXY_IP, port => $PROXY_PORT} => sub ($loop, $stream, $client) {    
    # Connection to client
    $stream->timeout(30); # increase stream timeout 
    $log->debug('client['.$client.'] connected');
    $stream->on(
      read => sub {
        my ($stream, $chunk) = @_;
	# Read and collect request(s) from client if the request holds CRLF and/or LF json-rpc 2.0 message can be collected
	my $chunk_error = 1;
	while($chunk =~ m/([^\x0a|\x0d\x0a]+)\x0d?\x0a/ig){ 
	    my $message  = $1;
	    my $json     = decode_json $message;
	    $chunk_error = 0; # got something that can be a json-rpc
	    
	    # unit test mirroring level 0 
	    if(exists $json->{mirror}){
		my $mirror = $json->{mirror};
		if($mirror->{level} == 0){
		    my $reply = encode_json {jsonrpc => '2.0', id => $json->{id}, result => 1, mirror => {level => 0}};
		    #$log->debug($reply);
		    Mojo::IOLoop->stream($client)->write($reply. "\x0a");
		    next;
		}
	    }
	    
	    # simple validate
	    my $error = &valid_json_rpc($json);
	    if($error){
		Mojo::IOLoop->stream($client)->write($error. "\n");
		Mojo::IOLoop->remove($client);
		return delete $buffer{$client};
	    }
	    my $method = $json->{method};
	    $log->debug('received from client: '. $message);
	    
	    # Connection to server
	    my $server = $buffer{$client}{connection};
	    if($server){
		$log->debug('upstream connection for client found in buffer - reusing');
		my $upstream = Mojo::IOLoop->stream($server);
		return &proxy_upstream($client, $upstream, $message, $method);
	    }
	    $log->debug('need new connect to upstream server');
	    $buffer{$client}{connection} = Mojo::IOLoop->client(
		{address => $AGENT_IP, port => $AGENT_PORT} => sub {
		    my ($loop, $err, $upstream) = @_;
		    # Connection to server failed
		    if ($err) {
			$log->error('Server error - upstream connection error['.$err.']!');
			my $bytes = encode_json {jsonrpc => '2.0', error => {code => '-32000', message => 'Server error - upstream connection error['.$err.']!'}, id => undef};
			Mojo::IOLoop->stream($client)->write($bytes. "\n");
			Mojo::IOLoop->remove($client);
			return delete $buffer{$client};
		    }
		    $upstream->on(
			read => sub {
			    my ($stream, $chunk) = @_;
			    $log->debug('upstream message received, relay to client');
			    my $req  = Mojo::Message::Request->new->parse($chunk);
			    my $body = $req->body; # no decoding
			    $log->debug($chunk);
			    Mojo::IOLoop->stream($client)->write($body."\x0a");
			    $log->debug('relayed back written');
			}
			);
		    
		    # Server closed connection
		    $upstream->on(
			close => sub {
			    $log->debug('upstream server closed');
			    Mojo::IOLoop->remove($client);
			    delete $buffer{$client};
			}
			);
		    $log->debug('sending data upstream');
		    &proxy_upstream($client, $upstream, $message, $method);		    
		});
	    $log->debug('end of loop messages has been relayed');
	    
	}

	if($chunk_error){
	    $log->error('Parse error - missing CTRL and/or LF');
	    $log->error($chunk);
	    my $bytes = encode_json {jsonrpc => '2.0', error => {code => '-32700', message => 'Parse error - missing CTRL and/or LF'}, id => undef};
	    Mojo::IOLoop->stream($client)->write($bytes. "\n");
	    Mojo::IOLoop->remove($client);
	}
	
    });

    # Client closed connection
    $stream->on(
	close => sub {
	    $log->debug('client closed connection');
	    my $buffer = delete $buffer{$client};
	    Mojo::IOLoop->remove($buffer->{connection}) if $buffer->{connection};
	}
	);
    }
    );

# simple json-rpc 2.0 validation
# returns 0 if valid or error message
sub valid_json_rpc($json){
    my $valid = 1;

    $valid = 0 if($json->{jsonrpc} ne '2.0');
    $valid = 0 if(! defined $json->{method});
    $valid = 0 if(! defined $json->{id});
    
    if(!$valid){
	$log->error('Invalid Request - missing required JSON-RPC 2.0 members!');
	$log->error(Dumper $json);
	return encode_json {jsonrpc => '2.0', error => {code => '-32600', message => 'Invalid Request - missing required JSON-RPC 2.0 members!'}, id => undef};
    }
    return 0;
}
#
# proxy request upstream
sub proxy_upstream($client, $upstream, $message, $method){
	    my $len  = length $message;

	    my $req = Mojo::Message::Request->new;
	    $req->parse("GET /$method HTTP/1.0\x0d\x0a");
	    $req->parse("Content-Length: $len\x0d\x0a");
	    $req->parse("User-Agent: tcp-proxy\x0d\x0a");
	    $req->parse("Host: $PROXY_IP\x0d\x0a");
	    $req->parse("Content-Type: application/json;charset=UTF-8\x0d\x0a\x0d\x0a");
	    $req->parse($message);

	    $log->debug($req->to_string);
	    $upstream->write($req->to_string);
}
# start server
print <<EOF;
Starting stratum+tcp stratum server at port $PROXY_PORT
EOF


# Stop gracefully
Mojo::IOLoop->recurring(1 => sub { });
local $SIG{INT} = local $SIG{TERM} = sub { Mojo::IOLoop->stop };
Mojo::IOLoop->start;

1;
