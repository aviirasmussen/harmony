package Harmony::Controller::Asic;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw(decode_json encode_json);
#
use Carp;
use Data::Dumper;
use Readonly;

# Action
sub version ($self) {
    my $version = $self->app->config->{version};
    $self->app->log->debug('ASIC version: '.$version);
    
    
    $self->render(text => '<div id="version">'.$version.'</div>');
}
sub banner ($self) {
    my $json = $self->req->json;
    my $body = $self->req->body;
    
    $self->app->log->debug('ASIC banner:');
    $self->app->log->debug("JSON:\n" . Dumper $json);
    $self->app->log->debug("BODY:\n" . Dumper $body);
    
}
1;
