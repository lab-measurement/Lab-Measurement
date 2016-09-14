
=head1 NAME

Lab::Moose::Instrument::Cache - Add device cache functionality to Moose::Instrument
drivers.

=head1 SYNOPSIS

in your driver:

 use Lab::Moose::Instrument::Cache;

 cache 'foobar' => (getter => 'get_foobar');

 sub get_foobar {
     my $self = shift;
     
     return $self->cached_foobar(
         $self->query(command => ...));
 }

 sub set_foobar {
     my ($self, $value) = @_;
     $self->write(command => ...);
     $self->cached_foobar($value);
 }

=head1 DESCRIPTION

This package exports a new Moose keyword: B<cache>.

Calling C<< cache key => (getter => $getter, isa => $type) >> will generate a
L<Moose attribute|Moose::Manual::Attributes> 'cached_key' with the following
properties: 

 is => 'rw',
 isa => $type,
 predicate => 'has_cached_key',
 clearer => 'clear_cached_key',
 default => sub {$_[0]->$getter},
 lazy => 1,
 init_arg => undef

The C<isa> argument is optional.

=cut

package Lab::Moose::Instrument::Cache;
use Moose::Role;
use MooseX::Params::Validate;

our $VERSION = '3.520';

Moose::Exporter->setup_import_methods( with_meta => ['cache'] );

use namespace::autoclean -also =>
    [qw/_add_cache_accessor _add_cache_attribute/];

sub _add_cache_attribute {
    my %args      = @_;
    my $meta      = $args{meta};
    my $attribute = $args{attribute};
    my $getter    = $args{getter};
    my $builder   = $args{builder};

    # Creat builder method for the entry.
    $meta->add_method(
        $builder => sub {
            my $self = shift;

            # FIXME: getter params: timeout, read_length
            my $value = $self->$getter();
            $self->$attribute($value);
        }
    );

    $args{meta}->add_attribute(
        $args{attribute} => (
            is        => 'rw',
            init_arg  => undef,
            builder   => $builder,
            lazy      => 1,
            predicate => $args{predicate},
            clearer   => $args{clearer},
            isa       => $args{isa},
        )
    );
}

sub cache {
    my ( $meta, $name, %options ) = @_;

    my @options = %options;
    validated_hash(
        \@options,
        getter => { isa => 'Str' },

        #setter => { isa => 'Str', optional => 1 },
        isa => { optional => 1 },
    );

    $options{meta} = $meta;
    $options{name} = $name;

    if ( not exists $options{isa} ) {
        $options{isa} = 'Any';
    }

    $options{attribute} = "cached_$name";
    $options{predicate} = "has_cached_$name";
    $options{clearer}   = "clear_cached_$name";
    $options{builder}   = $options{attribute} . '_builder';

    _add_cache_attribute(%options);

}

1;
