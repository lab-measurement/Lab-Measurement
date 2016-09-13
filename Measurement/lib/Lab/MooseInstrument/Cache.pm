package Lab::MooseInstrument::Cache;
use Moose::Role;
use MooseX::Params::Validate;

our $VERSION = '3.512';

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
