use Mojo::Base -strict, -signatures;
use Mojo::IOLoop;
use Mojo::Log;
use Mojo::JSON qw(decode_json encode_json);
#
use Data::Dumper;

#
my %buffer;
# Log to STDERR
my $log = Mojo::Log->new;
# Start server
Mojo::IOLoop->server(
  {port => 8021} => sub {
    my ($loop, $stream, $client) = @_;

    # Connection to client
    $log->debug('client['.$client.'] connected');
    $stream->on(
      read => sub {
        my ($stream, $chunk) = @_;


        # Read and collect request from client
        my $request = $buffer{$client}{client} .= $chunk;

	# if the request holds CRLF and or LF json-rpc message is collected
        if ($request =~ /(:?\x0d?\x0a|\x0d?\x0a\x0d?\x0a)$/) {
	    $buffer{$client}{client} = ''; # reset client message
	    $log->debug($request);
	}else{
	    $log->error('Parse error - missing CTRL and or LF');
	    $log->error($request);
	    my $bytes = encode_json {jsonrpc => '2.0', error => {code => '-32700', message => 'Parse error - missing CTRL and or LF'}, id => undef};
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

#
print <<EOF;
Starting tcp dump server
EOF

# Stop gracefully
Mojo::IOLoop->recurring(1 => sub { });
local $SIG{INT} = local $SIG{TERM} = sub { Mojo::IOLoop->stop };
Mojo::IOLoop->start;

1;
