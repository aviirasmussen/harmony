#
# Minimal tcp2http proxy server for stratum
#
#
use Mojo::Base -strict, -signatures;
use Mojo::IOLoop;
use Mojo::Headers;
use Mojo::Message::Request;
use Mojo::Log;
use Mojo::JSON qw(decode_json encode_json);
#
use Data::Dumper;

my %buffer;
my $port = 3210;
my $AGENT_IP = '192.168.1.32';
my $AGENT_PORT  = 8080;
# Log to STDERR
my $log = Mojo::Log->new;

Mojo::IOLoop->server(
    {port => $port} => sub ($loop, $stream, $id) {
	# Connection to client
	$log->debug('client['.$id.'] connected');
	$stream->on(
	    read => sub ($stream, $chunk) {
		# Get chunk from client and write to server
		my $server = $buffer{$id}{connection};
		if($server){
		    $log->debug('server for client found in buffer - reusing');
		    return Mojo::IOLoop->stream($server)->write($chunk);
		}else{
		    $log->debug('need new connect to upstream server');
		}
		# Read connect request from client
		my $buffer = $buffer{$id}{client} .= $chunk;
		# if buffer holds CRLF and or LF
		if ($buffer =~ /\x0d?\x0a$/) {
		    $buffer{$id}{client} = '';
		    my $json    = decode_json $buffer;
		    my $valid   = 1;
		    # simple json-rpc 2.0 validation
		    $valid = 0 if($json->{jsonrpc} ne '2.0');
		    $valid = 0 if(! defined $json->{method});
		    $valid = 0 if(! defined $json->{id});

		    if(!$valid){
			$log->error('Invalid Request - missing required JSON-RPC 2.0 members!');
			$log->error($buffer);
			my $bytes = encode_json {jsonrpc => '2.0', error => {code => '-32600', message => 'Invalid Request - missing required JSON-RPC 2.0 members!'}, id => undef};
			Mojo::IOLoop->stream($id)->write($bytes. "\n");
			Mojo::IOLoop->remove($id);
			return delete $buffer{$id};
		    }
		    # move request upstream
		    # Connection to server
		    $buffer{$id}{connection} = Mojo::IOLoop->client(
			{address => $AGENT_IP, port => $AGENT_PORT} => sub {
			    my ($loop, $err, $stream) = @_;
			    
			    # Connection to server failed
			    if ($err) {
				$log->error("Connection error for $AGENT_IP:$AGENT_PORT: $err");
				$log->error('Server error - upstream connection error['.$err.']!');
				my $bytes = encode_json {jsonrpc => '2.0', error => {code => '-32000', message => 'Server error - upstream connection error['.$err.']!'}, id => undef};
				Mojo::IOLoop->stream($id)->write($bytes. "\n");
				Mojo::IOLoop->remove($id);
				return delete $buffer{$id};
			    }
				
			    # Start forwarding data in both directions
			    $log->info("Forwarding to upstream HTTP server $AGENT_IP:$AGENT_PORT");
			    Mojo::IOLoop->stream($id)->write("HTTP/1.1 200 OK\x0d\x0a" . "Connection: keep-alive\x0d\x0a\x0d\x0a");
			    $stream->write("yalla");
			    # "GET / HTTP/1.1\x0d\x0a\x0d\x0a"
			    #$headers->content_length(42);
			    #$headers->content_type('text/plain');
			    #say $headers->to_string;
			    #Authorization: Basic c2RmZzpzZHJ0
			    #Host: 192.168.1.32:3000
			    #Accept: */*
			    #Accept-Encoding: deflate, gzip
			    #Content-type: application/json
			    #X-Mining-Extensions: longpoll midstate rollntime submitold
			    #Content-Length: 235
			    #User-Agent: bfgminer/5.4.2-unknown
			    
			    $stream->on(read => sub ($stream, $chunk) { Mojo::IOLoop->stream($id)->write($chunk) });
			    #$stream->on(read => sub ($stream, $chunk) { Mojo::IOLoop->stream($id)->write("GET /foo HTTP/1.1\x0d\x0a\x0d\x0a") });
			    # Server closed connection
			    $stream->on(
				close => sub {
				    $log->debug('closing server stream..');
				    Mojo::IOLoop->remove($id);
				    delete $buffer{$id};
				}
				);
			}
			);
		}else{
		    $log->error('Parse error - missing CTRL and or LF');
		    $log->error($buffer);
		    my $bytes = encode_json {jsonrpc => '2.0', error => {code => '-32700', message => 'Parse error - missing CTRL and or LF'}, id => undef};
		    Mojo::IOLoop->stream($id)->write($bytes. "\n");
		    Mojo::IOLoop->remove($id);
		}
	    }
	    );
	
	# Client closed connection
	$stream->on(
	    close => sub {
		print "Client closed connection \n";
		my $buffer = delete $buffer{$id};
		Mojo::IOLoop->remove($buffer->{connection}) if $buffer->{connection};
	    }
	    );
    }
    );

print "Starting stratum+tcp stratum server at port $port\n";
Mojo::IOLoop->start;
1;
