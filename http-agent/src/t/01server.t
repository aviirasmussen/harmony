#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use lib qw(../lib);

binmode STDIN, ':utf8';
binmode STDOUT, ':utf8';

use Test::More tests => 1;
use Test::Mojo;
use Mojo::JSON;
use Mojo::Base -strict;
use Data::Dumper;
use Readonly;
use Carp;
#
Readonly my $MY_SECRET => '12345678EacBANPvoUfaZCmv62tEcmSxG2ecf5SLEIkbozzd9ZB0O2j5gibPYNXjpekC1AEH7PWU8eh3wdqxFQUdRhNddUYUnTK8in3CvdsonxQ5Ti9BaNYx32vucL5TtvDDp8lafdwywZAK3XvmN8q6JOiguQEsq5XoqYEggZD98';
Readonly my $VERSION   => '1.02';
#
$ENV{MOJO_IOLOOP_DEBUG}="1";
#
STDOUT->autoflush;
#
my $test       = Test::Mojo->new('Harmony');
my $time       = time;



#$test->get_ok('/version')->status_is(200)->text_is('div#version' => $VERSION);
#$test->get_ok('/#skipcbcheck#xnsub' => {Accept => '*/*'} => json => {jsonrpc => '2.0', id => '1', method => 'server.banner', params => []});
$test->get_ok('/debug#xnsub' => {Accept => '*/*'} => json => {jsonrpc => '2.0', id => '1', method => 'server.banner', params => []});
done_testing();

