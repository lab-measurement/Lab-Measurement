package Lab::Moose::Connection::IsoBus;

#ABSTRACT: Connection back end to the Oxford Instruments IsoBus

use v5.20;

use Moose;
use MooseX::Params::Validate;
use Carp;
use namespace::autoclean;

has base_connection => (
	is => 'ro',
	isa => 'Lab::Moose::Connection'
);

has isobus_address => (
	is => 'ro',
	isa => 'Int'
);

sub BUILD {
    my $self = shift;

}

sub set_termchar {
	my $self = shift;
	my %args = @_;
	my $termchar = delete $args{termchar};

	$self->base_connection->set_termchar(termchar => $termchar, %args);
}

sub enable_read_termchar {
	my $self = shift;
	my %args = @_;

	$self->base_connection->enable_read_termchar(%args);
}


sub Write {
    my $self = shift;
	my %args = @_;
	my $cmd = delete $args{command};
	$cmd = "\@" . $self->isobus_address() . $cmd;
    $self->base_connection->Write(command => $cmd, %args );
}

sub Read {
    my $self = shift;
	my %args = @_;

    return $self->base_connection->Read( %args );
}

sub Clear {
	my $self = shift;
	my %args = @_;

	$self->base_connection->Clear( %args );
}

with 'Lab::Moose::Connection';

__PACKAGE__->meta->make_immutable();

1;
