package Lab::XPRESS::Sweep::LogBlock;

use Role::Tiny;
requires qw/LOG write_LOG/;
    
use 5.010;

use Carp;

use Data::Dumper;

sub LogBlock {
    my $self = shift;

    if (@_ % 2 != 0) {
	croak "expected hash";
    }

    my %args = @_;

    my $block = $args{block};
    if (not defined $block) {
	croak "missing mandatory parameter 'block'";
    }

    my $header = $args{header};
    if (not defined $header) {
	croak "missing mandatory parameter 'header'";
    }

    my $file = $args{datafile};
    if (not defined $file) {
	$file = 0;
    }

    my $external_params = $args{external_params};
    if (not defined $external_params) {
	$external_params = {};
    }

    
    my $rows = @$block;
    my $columns = @{$block->[0]};
    my $header_columns = @$header;
    
    if ($columns != $header_columns) {
	croak "header has $header_columns entries, block has $columns columns";
    }
    
    # Write external parameters and block to datafile
    
    for (my $row = 0; $row < $rows; ++$row) {
	my %log = %$external_params;
	
	for (my $col = 0; $col < $columns; ++$col) {
	    $log{$header->[$col]} = $block->[$row][$col];
	}
	$self->LOG({%log}, $file);
	
	if ($row != $rows - 1) {
	    # the last writeLOG is called in Sweep.pm
	    $self->write_LOG();
	}
	
    }
    
}
    

1;

