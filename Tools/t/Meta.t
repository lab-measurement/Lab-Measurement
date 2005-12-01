#!/usr/bin/perl
#$Id$
use strict;
use Data::Dumper;

use Test::More tests => 17;

BEGIN { use_ok('Lab::Data::Meta') };

ok(my $meta=new Lab::Data::Meta(),'create Meta object.');
is(ref $meta,'Lab::Data::Meta','is of right class.');

ok($meta->column_label(4,'test1'),'set column label with autoloader');
is($meta->{column}->[4]->{label},'test1','is set correctly');
is($meta->column_label(4),'test1','can be read back correctly');

ok(
    my $meta2=new Lab::Data::Meta({
        dataset_title  => "testtest",
        jibbet_nisch   => "nono",
        column         => [
            {label  =>'hallo'},
            {label  =>'selber hallo',
             unit   =>'mV'},
        ],
        axis           => {
            time    => {
                unit        => 's',
                description => 'the time',
            },
            energy  => {
                unit        => 'eV',
                description => 'kinetic energy',
            },
        },
    }
),'Create another Meta object.');
is(ref $meta,'Lab::Data::Meta','is of right class.');

is($meta2->dataset_title(),'testtest','has right title');
is($meta2->column_label(0),'hallo','1st column has right label');
ok($meta2->column_label(0,'ciao'),'1st column can be changed');
is($meta2->column_label(0),'ciao','1st column is changed');
is($meta2->column_unit(1),'mV','2nd column has right unit');
is($meta2->axis_unit('time'),'s','time axis has right unit');
is($meta2->axis_description('energy'),'kinetic energy','energy axis has right description');
is($meta2->{axis}->{energy}->{description},'kinetic energy','can also be accessed directly');
isnt($meta2->jibbet_nisch(),'nono','only allowed elements exist (XMLtree warning is ok)');