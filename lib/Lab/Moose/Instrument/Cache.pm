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
            return $self->$getter();
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
        getter => { isa      => 'Str' },
        isa    => { optional => 1, default => 'Any' },
    );

    my $getter    = $options{getter};
    my $isa       = $options{isa};
    my $function  = "cached_$name";
    my $attribute = "cached_${name}_attribute";
    my $builder   = "cached_${name}_builder";
    my $clearer   = "clear_cached_$name";
    my $predicate = "has_cached_$name";

    # Creat builder method for the entry.
    $meta->add_method(
        $builder => sub {
            my $self = shift;
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
            $self->$attribute( [] );
        }
    );

    $meta->add_method(
        $predicate => sub {
            my $self  = shift;
            my $array = $self->$attribute();
            if ( defined $array->[0] ) {
                return 1;
            }
            return;
        }
    );
}

1;
