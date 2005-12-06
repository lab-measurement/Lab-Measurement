#!/usr/bin/perl
#$Id$
use strict;
use Data::Dumper;

use Test::More tests => 34;

BEGIN { use_ok('Lab::Data::Meta') };

ok(my $meta=new Lab::Data::Meta(),'create Meta object.');
is(ref $meta,'Lab::Data::Meta','is of right class.');

ok($meta->column_label(4,'test1'),'set column #4\'s label with autoloader');
is($meta->{column}->[4]->{label},'test1','is set correctly');
is($meta->column_label(4),'test1','can be read back correctly');

ok($meta->column_label(0,'test2'),'set column #0\'s label with autoloader');
is($meta->{column}->[0]->{label},'test2','is set correctly');

ok($meta->axis_description('testachse','Dies ist eine Testachse'),'set axis description');
is($meta->{axis}->{testachse}->{description},'Dies ist eine Testachse','is set correctly');
is($meta->axis_description('testachse'),'Dies ist eine Testachse','can be read back correctly');

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

ok( my $meta3=new Lab::Data::Meta({
    data_complete			=> 0,
    dataset_title			=> 'newname',
    dataset_description		=> 'Imported by Importer.pm on '.(join "-",localtime(time)),
    data_file				=> "newname.DATA",
}),'Create yet another Meta object.');

for (0..2) {
    ok($meta3->column_label($_,'column '.($_)),"Set column #$_\'s label");
}
for (0..4) {
    ok($meta3->block_comment($_,"block $_"),"Set block #$_\'s comment");
}
for (qw/V_g1 V_g2 V_SD/) {
    ok($meta3->axis_description($_,"Dies ist die $_-Achse"),"Set description for axis $_");
}

$meta3->save("test.META");
