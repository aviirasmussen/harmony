package Harmony;
use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious', -signatures;
use Readonly;
use Data::Dumper;
#
#
Readonly my $RW_FILES => 0000;
Readonly my $HOME     => $ENV{'HOME'};
Readonly my $TRUE     => 1;
Readonly my $FALSE    => 0;
#
# umask $RW_FILES  will create log files in rw-rw-rw- (the leading 0 in value simply indicates an octal value).
my $last_mask = umask $RW_FILES;

#
# Loads configuration from hash returned by "harmony.conf", using plugin $CONFIG
# Loads helper methods, using plugin $HELPERS
sub startup ($self) {
    my $config  = $self->plugin('Config');

    $self->log->level('debug');
    #$self->log->info('new request');

    
    my $routes  = $self->routes;
    
    $routes->get( '/:cmd' => [cmd => ['server.version']] )->to('stratum#server_version');
    $routes->any(['GET', 'POST'] => '/')->to( controller => 'stratum', action => 'stratum');
    return $TRUE;
}
1;
