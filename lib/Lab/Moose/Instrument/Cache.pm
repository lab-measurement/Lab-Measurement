package Lab::Moose::Instrument::Cache;

#ABSTRACT: Role for device cache functionality in Moose::Instrument drivers

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
 builder => 'cached_key_builder',
 lazy => 1,
 init_arg => undef

The C<isa> argument is optional.

The builder method comes into play if a cache entry is in the cleared state. If
the getter is called in this situation, the builder
method will be used to generate the value.
The default builder method just calls the configured C<$getter> method.


If you need to call the getter with specific arguments, override the
builder method.
For example, the C<format_data_query> of the L<Lab::Moose::Instrument::RS_ZVM>
needs a timeout of 3s. This is done by putting the following into the
driver:

 sub cached_format_data_builder {
     my $self = shift;
     return $self->format_data_query( timeout => 3 );
 }



=cut

use Moose::Role;
use MooseX::Params::Validate;

Moose::Exporter->setup_import_methods( with_meta => ['cache'] );

use namespace::autoclean;

sub cache {
    my ( $meta, $name, %options ) = @_;

    my @options = %options;
    validated_hash(
        \@options,
        getter    => { isa      => 'Str' },
        isa       => { optional => 1, default => 'Any' },
        index_arg => { isa      => 'Str', optional => 1 },
    );

    my $getter         = $options{getter};
    my $isa            = $options{isa};
    my $index_arg      = $options{index_arg};
    my $have_index_arg = defined $index_arg;
    my $function       = "cached_$name";
    my $attribute      = "cached_${name}_attribute";
    my $builder        = "cached_${name}_builder";
    my $clearer        = "clear_cached_$name";
    my $predicate      = "has_cached_$name";

    # Creat builder method for the entry. The user can override this
    # in an instrument driver to add additional arguments to the getter.
    $meta->add_method(
        $builder => sub {
            my $self = shift;
            if ($have_index_arg) {
                my ($index) = validated_list(
                    \@_,
                    $index_arg => { isa => 'Int' }
                );
                return $self->$getter( $index_arg => $index );
            }
            return $self->$getter();
        }
    );

    $meta->add_attribute(
        $attribute => (
            is       => 'rw',
            init_arg => undef,
            isa      => 'ArrayRef',
            default  => sub { [] },
        )
    );

    $meta->add_method(
        $function => sub {
            my $self  = shift;
            my $array = $self->$attribute();

            if ($have_index_arg) {
                my ( $index, $value ) = validated_list(
                    \@_,
                    $index_arg => { isa      => 'Int' },
                    value      => { optional => 1 },
                );
                if ( defined $value ) {

                    # Store entry.
                    return $array->[$index] = $value;
                }

                # Query cache.
                if ( defined $array->[$index] ) {
                    return $array->[$index];
                }
                return $array->[$index]
                    = $self->$builder( $index_arg => $index );
            }

            # No vector index argument. Behave like usual Moose attribute.
            if ( @_ == 0 ) {

                # Query cache.
                if ( defined $array->[0] ) {
                    return $array->[0];
                }
                $array->[0] = $self->$builder();
                return $array->[0];
            }

            # Store entry.
            my ($value) = pos_validated_list( \@_, { isa => $isa } );
            $array->[0] = $value;
        }
    );

    $meta->add_method(
        $clearer => sub {
            my $self = shift;
            my $index;
            if ($have_index_arg) {

                # If no index is given, clear them all!
                ($index) = validated_list(
                    \@_,
                    $index_arg => { isa => 'Int', optional => 1 },
                );
            }
            if ( defined $index ) {
                $self->$attribute->[$index] = undef;
            }
            else {
                $self->$attribute( [] );
            }
        }
    );

    $meta->add_method(
        $predicate => sub {
            my $self  = shift;
            my $index = 0;
            if ($have_index_arg) {
                ($index) = validated_list(
                    \@_,
                    $index_arg => { isa => 'Int' }
                );
            }

            my $array = $self->$attribute();
            if ( defined $array->[$index] ) {
                return 1;
            }
            return;
        }
    );
}

1;
