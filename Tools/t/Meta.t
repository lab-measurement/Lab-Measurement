#!/usr/bin/perl
#$Id$
use strict;
use Data::Dumper;

use Test::More tests => 61;

BEGIN { use_ok('Lab::Data::Meta') };

ok(my $meta=new Lab::Data::Meta(),'meta1: create Meta object.');
is(ref $meta,'Lab::Data::Meta','meta1: is of right class.');

ok($meta->column_label(4,'test1'),'meta1: set column #4\'s label with autoloader');
is($meta->{column}->[4]->{label},'test1','meta1: is set correctly');
is($meta->column_label(4),'test1','meta1: can be read back correctly');

ok($meta->column_label(0,'test2'),'meta1: set column #0\'s label with autoloader');
is($meta->{column}->[0]->{label},'test2','meta1: is set correctly');

ok($meta->axis_description('testachse','meta1: Dies ist eine Testachse'),'set axis description');
is($meta->{axis}->{testachse}->{description},'meta1: Dies ist eine Testachse','is set correctly');
is($meta->axis_description('testachse'),'meta1: Dies ist eine Testachse','can be read back correctly');

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
),'meta2: Create another Meta object.');
is(ref $meta,'Lab::Data::Meta','meta2: is of right class.');

is($meta2->dataset_title(),'testtest','meta2: has right title');
is($meta2->column_label(0),'hallo','meta2: 1st column has right label');
ok($meta2->column_label(0,'ciao'),'meta2: 1st column can be changed');
is($meta2->column_label(0),'ciao','meta2: 1st column is changed');
is($meta2->column_unit(1),'mV','meta2: 2nd column has right unit');
is($meta2->axis_unit('time'),'s','meta2: time axis has right unit');
is($meta2->axis_description('energy'),'kinetic energy','meta2: energy axis has right description');
is($meta2->{axis}->{energy}->{description},'kinetic energy','meta2: can also be accessed directly');
isnt($meta2->jibbet_nisch(),'nono','meta2: only allowed elements exist (XMLtree warning is ok)');

my $testdescription=<<ENDE;
Dies ist die erste Zeile der Description.
Die zweite Zeile enthält Sonderzeichen: äöüß¤.

Nach einer Leerzeile hier nun Zeile 4.
In Zeile 5 droht Gefahr: <strong>Gefahr</strong>
ENDE
ok( my $meta3=new Lab::Data::Meta({
    data_complete			=> 0,
    dataset_title			=> 'newname',
    dataset_description		=> $testdescription,
    data_file				=> "newname.DATA",
}),'meta3: Create yet another Meta object.');

for (0..2) {
    ok($meta3->column_label($_,'column '.($_)),"meta3: Set column #$_\'s label");
}
for (0..4) {
    ok($meta3->block_comment($_,"block $_"),"meta3: Set block #$_\'s comment");
}
for (qw/V_g1 V_g2 V_SD/) {
    ok($meta3->axis_description($_,"Dies ist die $_-Achse"),"meta3: Set description for axis $_");
}
ok($meta3->data_complete(1),"meta3: Set data_complete.");

ok($meta3->save("test.META"),'meta3: Save as XML');

ok(my $meta4=Lab::Data::Meta->load('test.META'),'meta4: Create new Meta object (4) from file (with class method)');
ok(my $meta5=$meta3->load('test.META'),'meta5: Create new Meta object (5) from file (with object method)');

is($meta3->dataset_description(),$testdescription,'meta3: is right description');
is($meta4->dataset_description(),$testdescription,'meta4: is right description');
is($meta5->dataset_description(),$testdescription,'meta5: is right description');
is($meta3->data_complete(),1,'meta3: data_complete is good for Meta 3');
is($meta4->data_complete(),1,'meta4: data_complete is good for Meta 4');
is($meta5->data_complete(),1,'meta5: data_complete is good for Meta 5');
#print Dumper($meta5);
print $meta5->dataset_description();

#unlink "test.META";

is($meta3->column_label(2),'column 2','meta3: Column 2 is good for Meta 3');
is($meta4->column_label(2),'column 2','meta4: Column 2 is good for Meta 4');
is($meta5->column_label(2),'column 2','meta5: Column 2 is good for Meta 5');

is($meta3->column_label(0),'column 0','meta3: Column 0 is good for Meta 3');
is($meta4->column_label(0),'column 0','meta4: Column 0 is good for Meta 4');
is($meta5->column_label(0),'column 0','meta5: Column 0 is good for Meta 5');

is($meta3->block_comment(3),'block 3','meta3: Block 3 is good for Meta 3');
is($meta4->block_comment(3),'block 3','meta4: Block 3 is good for Meta 4');
is($meta5->block_comment(3),'block 3','meta5: Block 3 is good for Meta 5');

ok(my $m4_cols=$meta4->column(),'meta4: get column list reference');
is($#{$m4_cols},2,'meta4: list has right length');
ok(my @m4_cols=$meta4->column(),'meta4: get column list');
is($#m4_cols,2,'meta4: list has right length');

ok(my $m5_axes=$meta5->axis(),'meta5: get axes as hash reference');
is(scalar keys %{$m5_axes},3,'meta5: hash has right length');
ok(my %m5_axes=$meta5->axis(),'meta5: get axes as hash');
is(scalar keys %m5_axes,3,'meta5: hash has right length');
