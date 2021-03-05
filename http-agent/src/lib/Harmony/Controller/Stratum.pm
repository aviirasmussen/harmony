package Harmony::Controller::Stratum;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON qw(decode_json encode_json);
#
use Carp;
use Data::Dumper;
use Readonly;

sub server_version ($self) {
    $self->render_later;

    my $json    = $self->req->json;
    my $body    = $self->req->body;
    my $version = $self->app->config->{version};
    my $result  = {jsonrpc => '2.0', result => $version, id => $json->{id}};
    my $error   = {jsonrpc => '2.0', error => {code => '-32700', message => 'Parse error NO json'}, id => undef};

    if(!$json){
	return $self->render(json => $error);    	
    }
    
    $error = $self->_valid_json_rpc($json);

    if(!$error){
	return $self->render(json => $result);
    }
    return $self->render(json => $error);
}
sub stratum ($self) {
    my $json = $self->req->json;
    my $body = $self->req->body;
    $self->render(json => $json);    
    #$self->app->log->debug('STRATUM:');
    #$self->app->log->debug("JSON:\n" . Dumper $json);
    #$self->app->log->debug("BODY:\n" . Dumper $body);
    #$self->render(text => "stratum");
}
# simple json-rpc 2.0 validation
# returns 0 if valid or error message
sub _valid_json_rpc($self, $json){
    my $valid = 1;

    $valid = 0 if($json->{jsonrpc} ne '2.0');
    $valid = 0 if(! defined $json->{method});
    $valid = 0 if(! defined $json->{id});
    
    if(!$valid){
	$self->app->log->error('Invalid Request - missing required JSON-RPC 2.0 members!');
	$self->app->log->error(Dumper $json);
	return encode_json {jsonrpc => '2.0', error => {code => '-32600', message => 'Invalid Request - missing required JSON-RPC 2.0 members!'}, id => undef};
    }
    return 0;
}

1;
