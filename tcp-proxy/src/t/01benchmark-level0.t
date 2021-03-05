#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use Test::Mojo;

use Mojo::Base -strict;
use Mojo::Log;
use Mojo::IOLoop;
use Mojo::JSON qw(decode_json encode_json);

use Benchmark qw(:all) ;
use Data::Dumper;
use Readonly;
use Carp;

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

STDOUT->autoflush;


my $PROXY_IP   = '192.168.1.32';
my $PROXY_PORT = 3210;
my $test       = Test::Mojo->new;
my $time       = time;
my $server_ver = '1.02';
my $json       = { params => [ $server_ver], id => 0, jsonrpc => '2.0', method => 'server.version', mirror => {level => 0}};
my $log        = Mojo::Log->new;
#
my $COUNT      = 200;
my $COMPLETED  = 0;
#
my @CLIENTS    = ();

if(defined $ARGV[0]){
    $COUNT = $ARGV[0];
}
my $start = Benchmark->new;
# mirror level 0 
for(my $i=0;$i < $COUNT; $i++){
    push (@CLIENTS,  &aClient(0));
}
$log->level('info');	
$log->info('starting '.$COUNT.' clients with '.$COUNT.' requests');
Mojo::IOLoop->start;

done_testing();
sub onCompleted{
    if($COMPLETED == $COUNT){
	my $end = Benchmark->new;
	my $td  = timediff($end, $start);
	$log->info("All clients took:",timestr($td));
	
	$test->test('is', $COMPLETED, $COUNT, 'all_requests_completed');
	for(my $i=0; $i < scalar (@CLIENTS);$i++){
	    Mojo::IOLoop->remove($CLIENTS[$i]);
	}
	
    }
    return 1;
}
sub aClient {
    #my $t0;
    my $mirror_level = shift;
    my $id = Mojo::IOLoop->client({address => $PROXY_IP,  port => $PROXY_PORT} => sub {
	my ($loop, $err, $stream) = @_;
	if(! $stream){
	    $log->error($err);
	    return 0;
	}
	# Increase inactivity timeout for connection
	$stream->timeout(60);
	#$log->debug('client connected to json-rpc server');
	
	$stream->on(read => sub {
	    my ($stream, $bytes) = @_;
	    # Process input
	    #$log->debug($bytes);
	    $COMPLETED++;
	    &onCompleted();
		});
	
    for(my $i=0;$i < $COUNT; $i++){
	$json->{id} = $i;
	$json->{mirror}->{level} = $mirror_level;
	my $chunk = encode_json $json;
	#$log->debug('writing: '. $chunk);
	$stream->write($chunk. "\x0a");
    }
    
			      });
    push (@CLIENTS,  $id);
    #$log->debug('client '. $id.' ready');
return $id;
}
