#$Id$

package Lab::Data::Writer;

use strict;
use encoding::warnings;
use Data::Dumper;
use File::Basename;
use File::Copy;
use Lab::Data::Meta;

our $VERSION="1.41";

my $default_config = {
    output_data_ext     => "dat",
    output_meta_ext     => "meta",

    output_col_sep      => "\t",
    output_line_sep     => "\n",
    output_block_sep    => "\n",
    output_comment_char => "# ",
};

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);
    
    my $file=shift;
    $self->configure(shift);

    my ($filename,$path,$suffix)=fileparse($file, qr/\.[^.]*/);
    open my $log,">$path$filename.".$self->configure('output_data_ext') or die "Cannot open log file";
    my $old_fh = select($log);
    $| = 1;
    select($old_fh);
    $self->{filehandle}=$log;
    $self->{filename}=$filename;
    $self->{filepath}=$path;
    $self->{block_num}=0;
    
    return $self;
}

sub DESTROY {
    my $self=shift;
    close($self->{filehandle});
}


sub configure {
    my $self=shift;
    my $config=shift;

    if (defined($config) && !(ref $config)) {
        return $self->{Config}->{$config};
    }   
    for my $conf_name (keys %{$default_config}) {
        unless ((defined($self->{Config}->{$conf_name})) || (defined($config->{$conf_name}))) {
            $self->{Config}->{$conf_name}=$default_config->{$conf_name};
        } elsif (defined($self->{config}->{$conf_name})) {
            $self->{Config}->{$conf_name}=$config->{$conf_name};
        }
    }
}

sub get_filename {
    my $self=shift;
    return ($self->{filename},$self->{filepath});
}

sub log_comment {
    my ($self,$comment)=@_;
    my $fh=$self->{filehandle};
    for (split /\n|(\n\r)/, $comment) {
        print $fh $self->configure('output_comment_char'),$_,"\n";
    }
}

sub log_line {
    my ($self,@data)=@_;
    my $fh=$self->{filehandle};
    print $fh (join $self->configure('output_col_sep'),@data),$self->configure('output_line_sep');
}

sub log_start_block {
    my $self=shift;
    my $fh=$self->{filehandle};
    if ($self->{block_num}) {
        print $fh $self->configure('output_block_sep');
    }
    return $self->{block_num}++;
}

sub import_gpplus {
    my $self=shift;
    my %opts=@_;    #filename, newname, archive

    #print "Options: ",Dumper(\%opts);
    
    return "What should I import?" unless ((defined $opts{filename}) && ($opts{filename} ne ''));

    my ($filenamebase,$path,$suffix)=fileparse($opts{filename},qr/_\d+\.TSK/);
    my ($newname) = $opts{newname} =~ /[\/\\]?([^\/\\]+)$/;
    my $newpath=$opts{newname} || $filenamebase;
    $newpath.="/" unless ($newpath =~ /[\/\\]$/);
    for ($path,$filenamebase,$newpath) {
        s/\\/\//g;
        s/ /\\ /g;
    }
    $newname=$newname || $filenamebase;
    my $basename=$path.$filenamebase;
    #print "basename: $basename\nnewpath: $newpath\nnewname: $newname\n";
    my @files=sort {
        ($a =~ /$basename\_(\d+)\.TSK/)[0] <=> ($b =~ /$basename\_(\d+)\.TSK/)[0]
    } glob($basename."_*.TSK");

    #print "Files:\n ",(join "\n ",@files),"\n";
    return "Destination directory $newpath already exists" if (-d $newpath);
    return "Cannot create directory $newpath: $!\n" unless (mkdir $newpath);
        
    my $meta=new Lab::Data::Meta({
        data_complete           => 0,
        dataset_title           => $newname,
        dataset_description     => 'Imported by Importer.pm on '.(join "-",localtime(time)),
        data_file               => "$newname.".$self->configure('output_data_ext'),
    });
    $meta->save("$newpath$newname.".$self->configure('output_meta_ext'));
    
    open my $dataout,">$newpath$newname.".$self->configure('output_data_ext')
        || return "Cannot open output file $newpath$newname.".$self->configure('output_data_ext').": $!";
    
    my (@min,@max);
    my $blocknum=0;
    my $linenum=0;
    my $total_lines=0;
    my $numcol;
    my $ok=0;
    
    for my $old_file (@files) {
        open IN,"<$old_file" || return "Cannot open file $old_file: $!";
        while (<IN>) {
            $_=~s/[\n\r]+$//;
            if (/^([\d\-+\.Ee]+;)+/) {
                if (/E+37/) { print "Attention: Contains bad data due to overload!\n" }
                my @value=split ";";
                $self->log_line($dataout,@value);
                for (0..$#value) {
                    $min[$_]=$value[$_] if (!(defined $min[$_]) || ($value[$_] < $min[$_]));
                    $max[$_]=$value[$_] if (!(defined $max[$_]) || ($value[$_] > $max[$_]));
                }
                if (($linenum==0) && ($blocknum==0)) {
                    $numcol=$#value;
                    for (0..$numcol) {
                        $meta->column_label($_,'column '.($_+1));
                    }
                } elsif ($numcol!=$#value) {
                    die "spaltenzahl scheisse in zeile $linenum von block $blocknum.\n".
                        "sollte ".1+$numcol." sein. so habe ich keinen bock und sterbe jetzt";
                }
                $linenum++;$total_lines++;
            } elsif (/^Saved at ([\d:]{8}) on ([\d.]{8})/) {
                #Zeit und Datum werden von GPplus pro File/Block gespeichert
                my ($time,$date)=($1,$2);
                $meta->block_description($blocknum,"Saved at $time on $date");
                $meta->block_timestamp($blocknum,"$date-$time");
                $meta->block_original_filename($blocknum,$old_file);
            } elsif ($blocknum == 0) {
                #Kommentar
                $meta->dataset_description($meta->dataset_description().$_."\n")
                    if ($_ !~ /DATA MEASURED/);
            } else {
                #ignorierter Kommentar: GPplus schreibt gleichen Kommentar in jedes File
            }
        }
        close IN;
        $blocknum++;
        $self->log_finish_block($dataout);
        if ($linenum > 0) { $ok=1 }
        $linenum=0;
    }
    close $dataout;
    return "No data!\n" unless ($ok);

    chmod 0440,"$newpath$newname.".($self->configure('output_data_ext'))
        or warn "Cannot change permissions for newly created data file: $!\n";
    for (0..$#min) {
        $meta->column_min($_,$min[$_]);
        $meta->column_max($_,$max[$_]);
    }
    $meta->data_complete(1);
    $meta->save("$newpath$newname.".$self->configure('output_meta_ext'));
    my $archive_dir=$newpath."imported_gpplus";
    if ($opts{archive}) {
        return "Destination directory {$newpath}imported_gpplus already exists" if (-d $archive_dir);
        return "Cannot create directory {$newpath}imported_gpplus: $!\n" unless (mkdir $archive_dir);

        for my $old (@files) {
            my ($oldname,$oldpath,$oldsuffix)=fileparse($old,qr/\..*/);
            if ($opts{archive} eq 'move') {
                move $old,"$archive_dir/$oldname$oldsuffix" or warn "Cannot move file $old to archive: $!\n";
            } else {
                copy $old,"$archive_dir/$oldname$oldsuffix" or warn "Cannot copy file $old to archive: $!\n";
            }
            chmod 0440,"$archive_dir/$oldname$oldsuffix" or warn "Cannot change permissions: $!\n";
        }
    }
    return ($newpath,$newname,$#files,$total_lines,$numcol+1,$blocknum-1,$archive_dir);
}

1;

__END__

=head1 NAME

Lab::Data::Writer - Write data to disk

=head1 SYNOPSIS

    use Lab::Data::Writer;
    
    my $writer=new Lab::Data::Writer($filename,$config);

    $writer->log_comment("This is my test log");

    my $num=$writer->log_start_block();
    $writer->log_line(1,2,3);

=head1 DESCRIPTION

This module can be used to log data to a file, comfortably.

=head1 CONSTRUCTOR

=head2 new

    $writer=new Lab::Data::Writer($filename,$config);

See L<configure> below for available configuration options.

=head1 METHODS

=head2 configure

    $writer->configure(\%config);

Available options and default values are

    output_data_ext     => "dat",
    output_meta_ext     => "meta",

    output_col_sep      => "\t",
    output_line_sep     => "\n",
    output_block_sep    => "\n",
    output_comment_char => "# ",

=head2 get_filename

    ($filename,$filepath)=$writer->get_filename()

=head2 log_comment

    $writer->log_comment($comment);

Writes a comment to the file.

=head2 log_line

    $writer->log_line(@data);

Writes a line of data to the file.

=head2 log_start_block

    $num=$writer->log_start_block();

Starts a new data block.

=head2 import_gpplus(%opts)

Imports GPplus TSK-files. Valid parameters are

  filename => 'path/to/one/of/the/tsk-files',
  newname  => 'path/to/new/directory/newname',
  archive  => '[copy|move]'

The path C<path/to/new/directory/> must exist, while C<newname> shall not
exist there.

=head1 AUTHOR/COPYRIGHT

This is $Id$

Copyright 2004-2006 Daniel Schröer (L<http://www.danielschroeer.de>)

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
