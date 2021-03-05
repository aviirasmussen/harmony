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
my $json       = { params => [ $server_ver], id => 0, jsonrpc => '2.0', method => 'server.version'};
my $log        = Mojo::Log->new;
#
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
	    my $json = decode_json $bytes;
	    $log->debug($json->{result});
	    &onCompleted('server.version', $json->{result}, '1.02');
		});
	
    my $chunk = encode_json $json;
    #$log->debug('writing: '. $chunk);
    $stream->write($chunk. "\x0a");
    
			      });
$log->info('checking server version');
my $start = Benchmark->new;
Mojo::IOLoop->start;

done_testing();

sub onCompleted{
    my $method = shift;
    my $param  = shift;
    my $result = shift;
    my $end = Benchmark->new;
    my $td  = timediff($end, $start);
    $log->info($method. " request:",timestr($td));
	
    $test->test('is', $param, $result, $method. ' completed');
    Mojo::IOLoop->remove($id);
    return 1;
}
