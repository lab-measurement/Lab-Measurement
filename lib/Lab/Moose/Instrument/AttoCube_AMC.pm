package Lab::Moose::Instrument::AttoCube_AMC;
  
use 5.020;

use Moose;
use time::HiRes qw/time/;
use MooseX::Params::Validate;
use Lab::Moose::Instrument qw/validated_getter validated_setter/;
#use Lab::Moose::Instrument::Cache;
use Carp;
use namespace::autoclean;

use JSON::PP;
use Tie::IxHash;
 
# (1)
extends 'Lab::Moose::Instrument';

has 'request_id' => ( 
	is => 'rw', 
	isa => 'Int', 
	default => int(rand(100000))
);
has 'api_version' => ( 
	is => 'ro', 
	isa => 'Int', 
	default => 2
);
has 'language' => ( 
	is => 'ro', 
	isa => 'Int', 
	default => 0
);
has 'json' => (
	is => 'ro',
	isa => 'JSON::PP',
	default => sub { JSON::PP->new },
);
has 'response_qeue' => (
  is => 'rw',
  isa => 'HashRef',
  default => sub { {} },
)
 
# (3)
sub BUILD {
  my $self = shift;
  $self->clear();
  # $self->cls();
}
 
sub _send_command {
  my ($self, $method, $params, %args) = validated_list (
    \@_,
    method => { isa => 'Str' },
    params => { isa => 'ArrayRef' },
  );
  # TODO: list the arbitrary array %args really needed? check that!
  # Further check which type the content of params should have?

  # for checking, TODO: remove later
  print("This is method: $method, and this param: $params\n");

  # Create the JSON-RPC request TODO: change to JSON::RPC2 if it complies?
  # my $request = {
  #   id      => $self->request_id(), # You can increment this ID if needed
  #   params  => $params || {},
  # 	api 	  => 2,
  #   method  => $method,
  #   jsonrpc => "2.0",
  # };

  # Try to create an orderd hash for the JSON-RPC request
  tie my %request, 'Tie::IxHash',
    jsonrpc => "2.0",
    method  => $method,
    api 	  => 2,
    params  => $params || {},
    id      => $self->request_id(); 

  # Encode the request to JSON
  my $json_request = $self->json->encode(\%request);

  # Send the JSON request over the TCP socket
  $self->write(command => $json_request);
  
  # increment request id and store old id to return
  my $old_id = $self->request_id;
  $self->request_id($self->request_id + 1);
  
  return $old_id;  
}

sub _receive_response {
  my ($self, $response_id) = validated_list(
    \@_,
    response_id => { isa => 'Int' },
  );

  my $start_time = time();
  while(true) {
    # Check if response is in queue
    if exists $self->response_qeue->{$response_id} {
      my $response = $self->response_qeue->{$response_id};
      delete $self->response_qeue->{$response_id};
      return $response;
    }

    if time() - start_time > 10 {
      croak "Received no response from server after 10 seconds";
    }

    # TODO: Add a lock check?
    # Receive the response from the server
    my $response = $self->read();

    # Decode the JSON response
    my $decoded_response = $self->json->decode($response);

    # check if response id matches request id 
    if ($self->request_id != $decoded_response->{id}) {
      # add response to queue
      $self->response_qeue->{$decoded_response->{id}} = $decoded_response;
    } else {
      return $decoded_response;
    }
  }
}

sub request {
  my ($self, $method, $params, %args) = validated_list (
    @_,
    method => { isa => 'Str' },
    params => { isa => 'ArrayRef' },
  );
  my $request_id = $self->_send_command($method, $params, %args);
  return $self->_receive_response($request_id);
}

sub handle_error {
  my ($self, $response) = validated_list(
    \@_,
    response => { isa => 'HashRef' },
  );
  # Check for JSON-RPC protocol errors
  if 'error' in $response {
    my $error = $response->{error};
    croak "JSON-RPC Error occured: $error->{message} ($error->{code})\n";
  }
  # Check for AttoCube errors
  my $errNo = $response->{result}[0];
  # TODO: add ignoreFunctionError here as well?
  if ($errNo != 0 and $errNo != 'null') {
    my $errStr = $self.errorNumberToString($self->language, $errNo);
    croak "AttoCube Error: $errNo\nError Text: $errStr\n";
  }
  return $errNo;
}

sub measure {
  my ($self) = @_;

  # Use the send_json_rpc_command method to request a measurement
  my $result = $self->_send_command(method => 'com.attocube.amc.control.setSensorEnabled', params => [0, 1]);
  $result = $self->_send_command(method => 'com.attocube.amc.move.getPosition', params => [0]);
  $result = $self->_send_command(method => 'com.attocube.amc.control.getSensorEnabled', params => [0]);

  if (defined $result) {
    return $result;
  } else {
    die "Measurement failed\n";
  }

}
 
# (9)
__PACKAGE__->meta()->make_immutable();
1;
