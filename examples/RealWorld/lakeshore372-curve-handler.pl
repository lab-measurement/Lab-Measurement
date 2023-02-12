use lib 'C:\Users\LocalAdmin\lab-measurement\lib';
use Lab::Moose;
use 5.010;
use Data::Dumper;
use YAML::XS 'Dump';

use PDL::Graphics::Gnuplot;
use PDL;

my $lakeshore = instrument(
    type => 'Lakeshore372',
    connection_type => 'VISA::GPIB',
    connection_options => {pad => 12},
     
    input_channel => '1', # set default input channel for all method calls
    log_file => 'lakeshore-log-file.yml'
    );


# say "IDN: ", $lakeshore->idn();

# for my $curve (6) {
#     my %header = $lakeshore->get_curve_header(curve => $curve);
#     say "curve: $curve";
#     print Dump(\%header);
    
# }


# for my $index (1..200) {
#     my %point = $lakeshore->get_curve_point(curve => 6, index => $index);
#     if ($point{temp} > 1) {
# 	say "index: $index";
# 	print Dump(\%point);
#     }
# }

# CERNOX 1030

# header

# $lakeshore->curve_delete(curve => 21);
# sleep 1;
# $lakeshore->set_curve_header(
#     curve => 21,
#     name => "CERNOX CX1030",
#     SN => "STANDARD",
#     format => 4,
#     limit => 400,
#     coefficient => 1
#     );

# my %header = $lakeshore->get_curve_header(curve => 21);
# print Dump(\%header);
# # from https://www.lakeshore.com/products/categories/specification/temperature-products/cryogenic-temperature-sensors/cernox

# my @ohms = reverse qw/31312 13507 7855.7 2355.1 1540.1 1058.4 740.78 574.2 451.41 331.67 225.19 179.12 151.29 132.34 101.16 85.94 65.864 54.228 46.664 41.420 37.621 34.779 33.839/;
# my @temps = reverse qw/0.3 0.4 0.5 1 1.4 2 3 4.2 6 10 20 30 40 50 77.35 100 150 200 250 300 350 400 420/;

# my $length =  @ohms + 0;
# if (@temps != $length) {
#     die "bad number of points";
# }

# # by calibrating to Germanium we know that R(T=4.26K) = 632
# my $correction_factor = 632 / 568.85;


# for my $index (1..$length) {
#     my $ohms = $ohms[$index - 1];
#     # scale curve with vaue from 4.26K
#     $ohms = $ohms * $correction_factor;
#     my $log_ohms = log($ohms)/log(10);
#     $lakeshore->set_curve_point(
# 	curve => 21,
# 	index => $index,
# 	temp => $temps[$index - 1],
# 	units => $log_ohms,
# 	curvature => 0
# 	);
# }

# my $w = PDL::Graphics::Gnuplot->new('qt', persist => 1, {grid => 1, logscale => 'x'});
# $w->plot( {with => 'linespoints'}, [@temps], log10(pdl(@ohms)));
# # $w->plot( {with => 'linespoints'}, [@temps], pdl(@ohms));


# sleep 10000;

# %header = $lakeshore->get_curve_header(curve => 21);
# print Dump(\%header);


# # Germanium thermometer


# $lakeshore->curve_delete(curve => 22);
# sleep 1;
# $lakeshore->set_curve_header(
#     curve => 22,
#     name => "GR-200A",
#     SN => "29772",
#     format => 4,
#     limit => 6,
#     coefficient => 1
#     );

# # test data

# my @temps = qw/6.19865 5.49559 4.99061 4.58711 4.19716 3.99791 3.79891 3.59757 3.39738 3.19731 2.99563 2.80007 2.60232 2.39946 2.20044 2.00051 1.80062 1.60042 1.40026 1.29915 1.20178 1.15209 1.05144
# 0.950495 0.856385 0.764378 0.684987 0.609927 0.535912 0.476014 0.418046 0.367334 0.330263 0.310332 0.290362 0.260102 0.229726 0.203924 0.182336 0.162139 0.145895 0.128018 0.112040 9.56114e-2 8.39646e-2 7.36335e-2 6.36939e-2 5.67379e-2 5.19572e-2 4.80935e-2 4.39590e-2/;
# my @ohms = qw/16.9713 17.3448 17.7269 18.1215 18.6015 18.8929 19.2223 19.5986 20.0258 20.5140 21.0819 21.7191 22.4738 23.3887 24.4621 25.7718 27.3981 29.4955 32.2499 33.989 35.9633 37.1559 39.9247
# 43.4593 47.5452 52.6870 58.554 65.9060 75.7370 86.8450 101.879 120.61 139.657 152.696 168.609 199.998 244.904 301.793 371.238 467.605 584.050 783.930 1084.38 1642.46 2380.97 3549.91 5607.9 8237.1 11292.9 15147.4 22606.9/;

# my $length =  @ohms + 0;
# if (@temps != $length) {
#     die "bad number of points";
# }



# for my $index (1..$length) {
#     my $ohms = $ohms[$index - 1];
#     my $log_ohms = log($ohms)/log(10);
#     $lakeshore->set_curve_point(
# 	curve => 22,
# 	index => $index,
# 	temp => $temps[$index - 1],
# 	units => $log_ohms,
# 	curvature => 0
# 	);
# }


# my %header = $lakeshore->get_curve_header(curve => 22);
# print Dump(\%header);


# RuOx

$lakeshore->curve_delete(curve => 23);
sleep 1;
$lakeshore->set_curve_header(
    curve => 23,
    name => "RuOx",
    SN => "custom",
    format => 4,
    limit => 10,
    coefficient => 1
    );

# if R > 4201:
# T = 2.7921 * ln(R / 740)**(-3.8918)

# if R < 4201:
# T = 10**(A1 + A2*C1 + A3*C1^2 + A4*C1^3) with C1 = log(R)

sub T_of_R {
    my $R = shift;
    if ($R < 4201) {
	my $A1 = 314.22;
	my $A2 = -250.47;
	my $A3 = 66.891;
	my $A4 = -5.9985;
	my $C1 = log($R) / log(10);
	my $exponent = $A1
	    + $A2 * $C1
	    + $A3 * $C1**2
	    + $A4 * $C1**3;
	return 10**($exponent);
    }
    else {
	return 2.7921 * log($R / 740)**(-3.8918);
    }	    
}

my @ohms = map {10**(3.2 + $_/100)} (1..120);
my @temps = map {T_of_R($_)} @ohms;



my $length =  @ohms + 0;
if (@temps != $length) {
    die "bad number of points";
}



for my $index (1..$length) {
    my $ohms = $ohms[$index - 1];
    my $log_ohms = log($ohms)/log(10);
    $lakeshore->set_curve_point(
	curve => 23,
	index => $index,
	temp => $temps[$index - 1],
	units => $log_ohms,
	curvature => 0
	);
}



# my $w = PDL::Graphics::Gnuplot->new('qt', persist => 1, {grid => 1, logscale => 'x'});
# $w->plot( {with => 'linespoints'}, [@temps], log10(pdl(@ohms)));
# # $w->plot( {with => 'linespoints'}, [@temps], pdl(@ohms));


# sleep 10000;
