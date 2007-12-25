#!/usr/bin/perl

use strict;
use File::Basename;
use File::Spec;

my @files=qw!
    VISA/lib/Lab/VISA/Tutorial.pod
    VISA/VISA.pod
    Instrument/lib/Lab/Instrument.pm
    Instrument/lib/Lab/Instrument/HP34401A.pm
    Instrument/lib/Lab/Instrument/HP34970A.pm
    Instrument/lib/Lab/Instrument/IPS120_10.pm
    Instrument/lib/Lab/Instrument/Agilent81134A.pm
    Instrument/lib/Lab/Instrument/SR780.pm
    Instrument/lib/Lab/Instrument/HP8360.pm
    Instrument/lib/Lab/Instrument/Source.pm
    Instrument/lib/Lab/Instrument/KnickS252.pm
    Instrument/lib/Lab/Instrument/Yokogawa7651.pm
    Instrument/lib/Lab/Instrument/IOtech488.pm
    Instrument/lib/Lab/Instrument/Dummysource.pm
    Tools/lib/Lab/Measurement.pm
    Tools/lib/Lab/Data/Meta.pm
    Tools/lib/Lab/Data/Plotter.pm
    Tools/lib/Lab/Data/Writer.pm
    Tools/lib/Lab/Data/PDL.pm
    Tools/lib/Lab/Data/XMLtree.pm
    Tools/scripts/plotter.pl
!;
#    Tools/lib/Lab/Data/Dataset.pm

unless (-d 'makedoku_temp') {
    mkdir 'makedoku_temp';
}

my $eps=join "",<DATA>;
open EPS,">makedoku_temp/title.eps" or die;
binmode EPS;
print EPS $eps;
close EPS;

my $preamble=
'\documentclass[twoside,BCOR4mm,openright,pointlessnumbers,headexclude,a4paper,11pt,final]{scrreprt}   %bzw. twoside,openright,pointednumbers
\pagestyle{headings}
\usepackage[latin1]{inputenc}
\usepackage[T1]{fontenc}
\usepackage{textcomp}
\usepackage{listings}
\usepackage{graphicx}
\usepackage[ps2pdf,linktocpage,colorlinks=true,citecolor=blue,pagecolor=magenta,pdftitle={Lab::VISA documentation},pdfauthor={Daniel Schröer},pdfsubject=Manual]{hyperref}
\lstset{language=Perl,basicstyle=\footnotesize\ttfamily,breaklines=true,
        commentstyle=\rmfamily,
        keywordstyle=\color{red}\bfseries,stringstyle=\sffamily,
        identifierstyle=\color{blue}}

\begin{document}

\begin{titlepage}
\begin{flushleft}
\newcommand{\Rule}{\rule{\textwidth}{1pt}}
\sffamily
{\Large Daniel Schröer}
\vspace{5mm}

\Rule
\vspace{4mm}
{\Huge Documentation for Lab::VISA}
\vspace{5mm}\Rule

\vfill
\begin{center}
\includegraphics[width=12cm]{title}
\end{center}
\vfill
\today\ ($ $Revision$ $)

\end{flushleft}
\end{titlepage}
\cleardoublepage
\pdfbookmark[0]{\contentsname}{toc}
\tableofcontents
';

my $postamble='
\end{document}
';

open MAIN,'>makedoku_temp/documentation.tex' or die;
print MAIN $preamble;

for (@files) {
    my $parser = MyPod2LaTeX->new();
    $parser->AddPreamble(0);
    $parser->AddPostamble(0);
    $parser->LevelNoNum(2);
    $parser->ReplaceNAMEwithSection(1);
    $parser->TableOfContents(0);
    $parser->StartWithNewPage(0);
    $parser->select('!(AUTHOR.*|SEE ALSO|CAVEATS.*)');
    
    unless (-f $_) {
        warn "File $_ doesn't exist";
    } else {
        my $basename = fileparse($_,qr{\.(pod|pm)});
        $parser->Head1Level(0) if ($basename =~ /Tutorial/);
        $parser->parse_from_file ($_,qq(makedoku_temp/$basename.tex));
        for ($basename) {
            if      (/VISA/) { print MAIN "\\chapter{The Lab::VISA package}\n"}
            elsif   (/Instrument/) { print MAIN "\\chapter{The Lab::Instruments package}\n"}
            elsif   (/Measurement/) { print MAIN "\\chapter{The Lab::Tools package}\n"}
            else {print MAIN "\\cleardoublepage\n"}
        }
        print MAIN "\\input{$basename}\n";
    } 
}
print MAIN $postamble;
close MAIN;

chdir 'makedoku_temp';
for (1..3) {
    system('latex documentation.tex');
}
system('dvips -P pdf -t A4 documentation');
system('ps2pdf documentation.ps');
chdir '..';

rename('makedoku_temp/documentation.pdf','documentation.pdf') or warn "umbenennen geht nicht: $!";
if (chdir "makedoku_temp") {
    unlink(<*>) or warn "files löschen geht nicht $!";
    chdir "..";
}
rmdir 'makedoku_temp' or warn "tempdir löschen geht nicht: $!";

package MyPod2LaTeX;
use strict;
use base qw/ Pod::LaTeX /;

sub verbatim {
  my $self = shift;
  my ($paragraph, $line_num, $parobj) = @_;
  if ($self->{_dont_modify_any_para}) {
    $self->_output($paragraph);
  } else {
    return if $paragraph =~ /^\s+$/;
    $paragraph =~ s/\s+$//;
    my @l = split("\n",$paragraph);
    foreach (@l) {
      1 while s/(^|\n)([^\t\n]*)(\t+)/
	$1. $2 . (" " x 
		  (8 * length($3)
		   - (length($2) % 8)))
	  /sex;
    }
    $paragraph = join("\n",@l);
    $self->_output('\leavevmode\begin{lstlisting}' . "\n$paragraph\n". '\end{lstlisting}'."\n");
  }
}

__END__

%!PS-Adobe-3.0 EPSF-3.0
%%BoundingBox: 81 291 390 649 
%%LanguageLevel: 2
%%Creator: CorelDRAW
%%Title: dokutitel.eps
%%CreationDate: Sun Aug 13 23:34:23 2006
%%For: Daniel Schröer
%%DocumentProcessColors: Black 
%%DocumentSuppliedResources: (atend)
%%EndComments
%%BeginProlog
/AutoFlatness false def
/AutoSteps 0 def
/CMYKMarks true def
/UseLevel 2 def
%Build: CorelDRAW Version 13.0.0.576
%Color profile:  Generisches Offset-Auszugsprofil
/CorelIsEPS true def
%%BeginResource: procset wCorel3Dict 3.0 0
/wCorel3Dict 300 dict def wCorel3Dict begin
% Copyright (c)1992-2005 Corel Corporation
% All rights reserved.     v13 r0.0
/bd{bind def}bind def/ld{load def}bd/xd{exch def}bd/_ null def/rp{{pop}repeat}
bd/@cp/closepath ld/@gs/gsave ld/@gr/grestore ld/@np/newpath ld/Tl/translate ld
/$sv 0 def/@sv{/$sv save def}bd/@rs{$sv restore}bd/spg/showpage ld/showpage{}
bd currentscreen/@dsp xd/$dsp/@dsp def/$dsa xd/$dsf xd/$sdf false def/$SDF
false def/$Scra 0 def/SetScr/setscreen ld/@ss{2 index 0 eq{$dsf 3 1 roll 4 -1
roll pop}if exch $Scra add exch load SetScr}bd/SepMode_5 where{pop}{/SepMode_5
0 def}ifelse/CorelIsSeps where{pop}{/CorelIsSeps false def}ifelse
/CorelIsInRIPSeps where{pop}{/CorelIsInRIPSeps false def}ifelse/CorelIsEPS
where{pop}{/CorelIsEPS false def}ifelse/CurrentInkName_5 where{pop}
{/CurrentInkName_5(Composite)def}ifelse/$ink_5 where{pop}{/$ink_5 -1 def}
ifelse/fill_color 6 array def/num_fill_inks 1 def/$o 0 def/$fil 0 def
/outl_color 6 array def/num_outl_inks 1 def/$O 0 def/$PF false def/$bkg false
def/$op false def matrix currentmatrix/$ctm xd/$ptm matrix def/$ttm matrix def
/$stm matrix def/$ffpnt true def/CorelDrawReencodeVect[16#0/grave 16#5/breve
16#6/dotaccent 16#8/ring 16#A/hungarumlaut 16#B/ogonek 16#C/caron 16#D/dotlessi
16#27/quotesingle 16#60/grave 16#7C/bar 16#80/Euro
16#82/quotesinglbase/florin/quotedblbase/ellipsis/dagger/daggerdbl
16#88/circumflex/perthousand/Scaron/guilsinglleft/OE
16#91/quoteleft/quoteright/quotedblleft/quotedblright/bullet/endash/emdash
16#98/tilde/trademark/scaron/guilsinglright/oe 16#9F/Ydieresis
16#A1/exclamdown/cent/sterling/currency/yen/brokenbar/section
16#a8/dieresis/copyright/ordfeminine/guillemotleft/logicalnot/minus/registered/macron
16#b0/degree/plusminus/twosuperior/threesuperior/acute/mu/paragraph/periodcentered
16#b8/cedilla/onesuperior/ordmasculine/guillemotright/onequarter/onehalf/threequarters/questiondown
16#c0/Agrave/Aacute/Acircumflex/Atilde/Adieresis/Aring/AE/Ccedilla
16#c8/Egrave/Eacute/Ecircumflex/Edieresis/Igrave/Iacute/Icircumflex/Idieresis
16#d0/Eth/Ntilde/Ograve/Oacute/Ocircumflex/Otilde/Odieresis/multiply
16#d8/Oslash/Ugrave/Uacute/Ucircumflex/Udieresis/Yacute/Thorn/germandbls
16#e0/agrave/aacute/acircumflex/atilde/adieresis/aring/ae/ccedilla
16#e8/egrave/eacute/ecircumflex/edieresis/igrave/iacute/icircumflex/idieresis
16#f0/eth/ntilde/ograve/oacute/ocircumflex/otilde/odieresis/divide
16#f8/oslash/ugrave/uacute/ucircumflex/udieresis/yacute/thorn/ydieresis]def
/get_ps_level/languagelevel where{pop systemdict/languagelevel get exec}{1
}ifelse def/level2 get_ps_level 2 ge def/level3 get_ps_level 3 ge def
/is_distilling{/product where{pop systemdict/setdistillerparams known product
(Adobe PostScript Parser)ne and}{false}ifelse}bd/is_rip_separation{
is_distilling{false}{level2{currentpagedevice/Separations 2 copy known{get}{
pop pop false}ifelse}{false}ifelse}ifelse}bd/is_current_sep_color{
is_separation{gsave false setoverprint 1 1 1 1 5 -1 roll findcmykcustomcolor 1
setcustomcolor currentgray 0 eq grestore}{pop false}ifelse}bd
/get_sep_color_index{dup length 1 sub 0 1 3 -1 roll{dup 3 -1 roll dup 3 -1 roll
get is_current_sep_color{exit}{exch pop}ifelse}for pop -1}bd/is_separation{
/LumSepsDict where{pop false}{/AldusSepsDict where{pop false}{
is_rip_separation{true}{1 0 0 0 gsave setcmykcolor currentcmykcolor grestore
add add add 0 ne 0 1 0 0 gsave setcmykcolor currentcmykcolor grestore add add
add 0 ne 0 0 1 0 gsave setcmykcolor currentcmykcolor grestore add add add 0 ne
0 0 0 1 gsave setcmykcolor currentcmykcolor grestore add add add 0 ne and and
and not}ifelse}ifelse}ifelse}bind def/is_composite{is_separation not
is_distilling or}bd/is_sim_devicen{level2 level3 not and{is_distilling
is_rip_separation or}{false}ifelse}bd/@PL{/LV where{pop LV 2 ge level2 not and
{@np/Courier findfont 12 scalefont setfont 72 144 m
(The PostScript level set in the Corel application is higher than)show 72 132 m
(the PostScript level of this device. Change the PS Level in the Corel)show 72
120 m(application to Level 1 by selecting the PostScript tab in the print)show
72 108 m(dialog, and selecting Level 1 from the Compatibility drop down list.)
show flush spg quit}if}if}bd/@BeginSysCorelDict{systemdict/Corel30Dict known
{systemdict/Corel30Dict get exec}if systemdict/CorelLexDict known{1 systemdict
/CorelLexDict get exec}if}bd/@EndSysCorelDict{systemdict/Corel30Dict known
{end}if/EndCorelLexDict where{pop EndCorelLexDict}if}bd AutoFlatness{/@ifl{dup
currentflat exch sub 10 gt{
([Error: PathTooComplex; OffendingCommand: AnyPaintingOperator]\n)print flush
@np exit}{currentflat 2 add setflat}ifelse}bd/@fill/fill ld/fill{currentflat{
{@fill}stopped{@ifl}{exit}ifelse}bind loop setflat}bd/@eofill/eofill ld/eofill
{currentflat{{@eofill}stopped{@ifl}{exit}ifelse}bind loop setflat}bd/@clip
/clip ld/clip{currentflat{{@clip}stopped{@ifl}{exit}ifelse}bind loop setflat}
bd/@eoclip/eoclip ld/eoclip{currentflat{{@eoclip}stopped{@ifl}{exit}ifelse}
bind loop setflat}bd/@stroke/stroke ld/stroke{currentflat{{@stroke}stopped
{@ifl}{exit}ifelse}bind loop setflat}bd}if level2{/@ssa{true setstrokeadjust}
bd}{/@ssa{}bd}ifelse/d/setdash ld/j/setlinejoin ld/J/setlinecap ld/M
/setmiterlimit ld/w/setlinewidth ld/O{/$o xd}bd/R{/$O xd}bd/W/eoclip ld/c
/curveto ld/C/c ld/l/lineto ld/L/l ld/rl/rlineto ld/m/moveto ld/n/newpath ld/N
/newpath ld/P{11 rp}bd/u{}bd/U{}bd/A{pop}bd/q/@gs ld/Q/@gr ld/&{}bd/@j{@sv @np}
bd/@J{@rs}bd/g{1 exch sub 0 0 0 1 null 1 set_fill_color/$fil 0 def}bd/G{1 sub
neg 0 0 0 1 null 1 set_outline_color}bd/set_fill_color{/fill_color exch def
/num_fill_inks fill_color length 6 idiv def/bFillDeviceN num_fill_inks 1 gt def
/$fil 0 def}bd/set_outline_color{/outl_color exch def/num_outl_inks outl_color
length 6 idiv def/bOutlDeviceN num_outl_inks 1 gt def}bd
/get_devicen_color_names{dup length 6 idiv dup 5 mul exch getinterval}bd
/get_devicen_color_specs{dup length 6 idiv dup 4 mul getinterval}bd
/get_devicen_color{dup length 6 idiv 0 exch getinterval}bd/mult_devicen_color{
/colorarray exch def/mult_vals exch def 0 1 mult_vals length 1 sub{colorarray
exch dup mult_vals exch get exch dup colorarray exch get 3 -1 roll mul put}for
colorarray}bd/combine_devicen_colors{/colorarray2 exch def/colorarray1 exch def
/num_inks1 colorarray1 length 6 idiv def/num_inks2 colorarray2 length 6 idiv
def/num3 0 def/colorarray3[num_inks1 num_inks2 add 6 mul{0}repeat]def 0 1
num_inks1 1 sub{colorarray1 exch get colorarray3 num3 3 -1 roll put/num3 num3 1
add def}for 0 1 num_inks2 1 sub{colorarray2 exch get colorarray3 num3 3 -1 roll
put/num3 num3 1 add def}for colorarray1 num_inks1 dup 4 mul getinterval
colorarray3 num3 3 -1 roll putinterval/num3 num3 num_inks1 4 mul add def
colorarray2 num_inks2 dup 4 mul getinterval colorarray3 num3 3 -1 roll
putinterval/num3 num3 num_inks2 4 mul add def colorarray1 num_inks1 dup 5 mul
exch getinterval colorarray3 num3 3 -1 roll putinterval/num3 num3 num_inks1 add
def colorarray2 num_inks2 dup 5 mul exch getinterval colorarray3 num3 3 -1 roll
putinterval/num3 num3 num_inks2 add def colorarray3}bd/get_devicen_color_spec{
/colorant_index exch def/colorarray exch def/ncolorants colorarray length 6
idiv def[colorarray colorant_index get colorarray ncolorants colorant_index 4
mul add 4 getinterval aload pop colorarray ncolorants 5 mul colorant_index add
get]}bd/set_devicen_color{level3{/colorarray exch def/numcolorants colorarray
length 6 idiv def colorarray get_devicen_color_specs/tint_params exch def[
/DeviceN colorarray get_devicen_color_names/DeviceCMYK{tint_params
CorelTintTransformFunction}]setcolorspace colorarray get_devicen_color aload
pop setcolor}{/DeviceCMYK setcolorspace devicen_to_cmyk aload pop pop @tc_5
setprocesscolor_5}ifelse}bd/sf{/bmp_fill_fg_color xd}bd/i{dup 0 ne{setflat}
{pop}ifelse}bd/v{4 -2 roll 2 copy 6 -2 roll c}bd/V/v ld/y{2 copy c}bd/Y/y ld
/@w{matrix rotate/$ptm xd matrix scale $ptm dup concatmatrix/$ptm xd 1 eq{$ptm
exch dup concatmatrix/$ptm xd}if 1 w}bd/@g{1 eq dup/$sdf xd{/$scp xd/$sca xd
/$scf xd}if}bd/@G{1 eq dup/$SDF xd{/$SCP xd/$SCA xd/$SCF xd}if}bd/@D{2 index 0
eq{$dsf 3 1 roll 4 -1 roll pop}if 3 copy exch $Scra add exch load SetScr/$dsp
xd/$dsa xd/$dsf xd}bd/$ngx{$SDF{$SCF SepMode_5 0 eq{$SCA}{$dsa}ifelse $SCP @ss
}if}bd/@MN{2 copy le{pop}{exch pop}ifelse}bd/@MX{2 copy ge{pop}{exch pop}
ifelse}bd/InRange{3 -1 roll @MN @MX}bd/@sqr{dup 0 rl dup 0 exch rl neg 0 rl @cp
}bd/currentscale{1 0 dtransform matrix defaultmatrix idtransform dup mul exch
dup mul add sqrt 0 1 dtransform matrix defaultmatrix idtransform dup mul exch
dup mul add sqrt}bd/@unscale{}bd/wDstChck{2 1 roll dup 3 -1 roll eq{1 add}if}
bd/@dot{dup mul exch dup mul add 1 exch sub}bd/@lin{exch pop abs 1 exch sub}bd
/cmyk2rgb{3{dup 5 -1 roll add 1 exch sub dup 0 lt{pop 0}if exch}repeat pop}bd
/rgb2cmyk{3{1 exch sub 3 1 roll}repeat 3 copy @MN @MN 3{dup 5 -1 roll sub neg
exch}repeat}bd/rgb2g{2 index .299 mul 2 index .587 mul add 1 index .114 mul add
4 1 roll pop pop pop}bd/devicen_to_cmyk{/convertcolor exch def convertcolor
get_devicen_color aload pop convertcolor get_devicen_color_specs
CorelTintTransformFunction}bd/WaldoColor_5 where{pop}{/SetRgb/setrgbcolor ld
/GetRgb/currentrgbcolor ld/SetGry/setgray ld/GetGry/currentgray ld/SetRgb2
systemdict/setrgbcolor get def/GetRgb2 systemdict/currentrgbcolor get def
/SetHsb systemdict/sethsbcolor get def/GetHsb systemdict/currenthsbcolor get
def/rgb2hsb{SetRgb2 GetHsb}bd/hsb2rgb{3 -1 roll dup floor sub 3 1 roll SetHsb
GetRgb2}bd/setcmykcolor where{pop/LumSepsDict where{pop/SetCmyk_5{LumSepsDict
/setcmykcolor get exec}def}{/AldusSepsDict where{pop/SetCmyk_5{AldusSepsDict
/setcmykcolor get exec}def}{/SetCmyk_5/setcmykcolor ld}ifelse}ifelse}{
/SetCmyk_5{cmyk2rgb SetRgb}bd}ifelse/currentcmykcolor where{pop/GetCmyk
/currentcmykcolor ld}{/GetCmyk{GetRgb rgb2cmyk}bd}ifelse/setoverprint where
{pop}{/setoverprint{/$op xd}bd}ifelse/currentoverprint where{pop}{
/currentoverprint{$op}bd}ifelse/@tc_5{5 -1 roll dup 1 ge{pop}{4{dup 6 -1 roll
mul exch}repeat pop}ifelse}bd/@trp{exch pop 5 1 roll @tc_5}bd
/setprocesscolor_5{SepMode_5 0 eq{SetCmyk_5}{SepsColor not{4 1 roll pop pop pop
1 exch sub SetGry}{SetCmyk_5}ifelse}ifelse}bd/findcmykcustomcolor where{pop}{
/findcmykcustomcolor{5 array astore}bd}ifelse/Corelsetcustomcolor_exists false
def/setcustomcolor where{pop/Corelsetcustomcolor_exists true def}if CorelIsSeps
true eq CorelIsInRIPSeps false eq and{/Corelsetcustomcolor_exists false def}if
Corelsetcustomcolor_exists false eq{/setcustomcolor{exch aload pop SepMode_5 0
eq{pop @tc_5 setprocesscolor_5}{CurrentInkName_5 eq{4 index}{0}ifelse 6 1 roll
5 rp 1 sub neg SetGry}ifelse}bd}if/@scc_5{dup type/booleantype eq{dup
currentoverprint ne{setoverprint}{pop}ifelse}{1 eq setoverprint}ifelse dup _ eq
{pop setprocesscolor_5 pop}{dup(CorelRegistrationColor)eq{5 rp 1 exch sub
setregcolor}{findcmykcustomcolor exch setcustomcolor}ifelse}ifelse SepMode_5 0
eq{true}{GetGry 1 eq currentoverprint and not}ifelse}bd/separate_color{
SepMode_5 0 ne{[exch/colorarray_sep exch def/ink_num -1 def colorarray_sep
length 6 idiv 1 gt{colorarray_sep get_devicen_color_names dup length 1 sub 0 1
3 -1 roll{exch dup 3 -1 roll dup 3 1 roll get CurrentInkName_5 eq{/ink_num exch
def}{pop}ifelse}for pop ink_num -1 ne{colorarray_sep ink_num
get_devicen_color_spec aload pop pop SepsColor not{pop pop pop pop 1 0 0 0 5 -1
roll}if null}{0 0 0 0 0 null}ifelse}{colorarray_sep 5 get $ink_5 4 eq{
CurrentInkName_5 eq{colorarray_sep aload pop pop SepsColor not{pop pop pop pop
0 0 0 1}if null}{0 0 0 0 0 null}ifelse}{colorarray_sep 0 get colorarray_sep
$ink_5 1 add get 3 -1 roll null eq{0 0 0 4 -1 roll SepsColor{4 $ink_5 1 add
roll}if null}{pop pop 0 0 0 0 0 null}ifelse}ifelse}ifelse]}if}bd
/separate_cmyk_color{$ink_5 -1 ne{[exch aload pop 3 $ink5 sub index
/colorarray_sep exch def/ink_num -1 def colorarray_sep get_devicen_color_names
dup length 1 sub 0 1 3 -1 roll{exch dup 3 -1 roll dup 3 1 roll get
CurrentInkName_5 eq{/ink_num exch def}{pop}ifelse}for pop ink_num -1 ne{[
colorarray_sep ink_num get_devicen_color_spec aload pop]}{[0 0 0 0 0 null]
}ifelse}if}bd/set_current_color{dup type/booleantype eq{dup currentoverprint ne
{setoverprint}{pop}ifelse}{1 eq setoverprint}ifelse/cur_color exch def
/nNumColors cur_color length 6 idiv def nNumColors 1 eq{cur_color 5 get
(CorelRegistrationColor)eq{cur_color aload pop 5 rp 1 exch sub setregcolor}{
SepMode_5 0 eq{cur_color aload pop dup null eq{pop @tc_5 setprocesscolor_5}{
findcmykcustomcolor exch setcustomcolor}ifelse}{cur_color separate_color aload
pop pop @tc_5 setprocesscolor_5}ifelse}ifelse}{SepMode_5 0 eq{is_distilling
is_rip_separation or{cur_color set_devicen_color}{cur_color devicen_to_cmyk
setprocesscolor_5}ifelse}{cur_color separate_color aload pop pop @tc_5
setprocesscolor_5}ifelse}ifelse SepMode_5 0 eq{true}{GetGry 1 eq
currentoverprint and not}ifelse}bd/colorimage where{pop/ColorImage{colorimage}
def}{/ColorImage{/ncolors xd/$multi xd $multi true eq{ncolors 3 eq{/daqB xd
/daqG xd/daqR xd pop pop exch pop abs{daqR pop daqG pop daqB pop}repeat}{/daqK
xd/daqY xd/daqM xd/daqC xd pop pop exch pop abs{daqC pop daqM pop daqY pop daqK
pop}repeat}ifelse}{/dataaq xd{dataaq ncolors dup 3 eq{/$dat xd 0 1 $dat length
3 div 1 sub{dup 3 mul $dat 1 index get 255 div $dat 2 index 1 add get 255 div
$dat 3 index 2 add get 255 div rgb2g 255 mul cvi exch pop $dat 3 1 roll put}
for $dat 0 $dat length 3 idiv getinterval pop}{4 eq{/$dat xd 0 1 $dat length 4
div 1 sub{dup 4 mul $dat 1 index get 255 div $dat 2 index 1 add get 255 div
$dat 3 index 2 add get 255 div $dat 4 index 3 add get 255 div cmyk2rgb rgb2g
255 mul cvi exch pop $dat 3 1 roll put}for $dat 0 $dat length ncolors idiv
getinterval}if}ifelse}image}ifelse}bd}ifelse/setcmykcolor{1 5 1 roll null 6
array astore currentoverprint set_current_color/$ffpnt xd}bd/currentcmykcolor{
GetCmyk}bd/setrgbcolor{rgb2cmyk setcmykcolor}bd/currentrgbcolor{
currentcmykcolor cmyk2rgb}bd/sethsbcolor{hsb2rgb setrgbcolor}bd
/currenthsbcolor{currentrgbcolor rgb2hsb}bd/setgray{dup dup setrgbcolor}bd
/currentgray{currentrgbcolor rgb2g}bd/InsideDCS false def/IMAGE/image ld/image
{InsideDCS{IMAGE}{/EPSDict where{pop SepMode_5 0 eq{IMAGE}{dup type/dicttype eq
{dup/ImageType get 1 ne{IMAGE}{dup dup/BitsPerComponent get 8 eq exch
/BitsPerComponent get 1 eq or currentcolorspace 0 get/DeviceGray eq and{
CurrentInkName_5(Black)eq{IMAGE}{dup/DataSource get/TCC xd/Height get abs{TCC
pop}repeat}ifelse}{IMAGE}ifelse}ifelse}{2 index 1 ne{CurrentInkName_5(Black)eq
{IMAGE}{/TCC xd pop pop exch pop abs{TCC pop}repeat}ifelse}{IMAGE}ifelse}
ifelse}ifelse}{IMAGE}ifelse}ifelse}bd}ifelse/WaldoColor_5 true def/$fm 0 def
/wfill{1 $fm eq{fill}{eofill}ifelse}bd/@Pf{@sv SepMode_5 0 eq $Psc 0 ne or
$ink_5 3 eq or{0 J 0 j[]0 d fill_color $o set_current_color pop $ctm setmatrix
72 1000 div dup matrix scale dup concat dup Bburx exch Bbury exch itransform
ceiling cvi/Bbury xd ceiling cvi/Bburx xd Bbllx exch Bblly exch itransform
floor cvi/Bblly xd floor cvi/Bbllx xd $Prm aload pop $Psn load exec}{1 SetGry
wfill}ifelse @rs @np}bd/F{matrix currentmatrix $sdf{$scf $sca $scp @ss}if $fil
1 eq{CorelPtrnDoFill}{$fil 2 eq{@ff}{$fil 3 eq{@Pf}{level3{fill_color $o
set_current_color{wfill}{@np}ifelse}{/overprint_flag $o def is_distilling
is_rip_separation or{0 1 num_fill_inks 1 sub{dup 0 gt{/overprint_flag true def
}if fill_color exch get_devicen_color_spec overprint_flag set_current_color{
@gs wfill @gr}{@np exit}ifelse}for}{fill_color overprint_flag set_current_color
{@gs wfill @gr}{@np exit}ifelse}ifelse}ifelse}ifelse}ifelse}ifelse $sdf{$dsf
$dsa $dsp @ss}if setmatrix}bd/f{@cp F}bd/S{matrix currentmatrix $ctm setmatrix
$SDF{$SCF $SCA $SCP @ss}if level3{outl_color $O set_current_color{matrix
currentmatrix $ptm concat stroke setmatrix}{@np}ifelse}{/overprint_flag $O def
is_distilling is_rip_separation or{0 1 num_outl_inks 1 sub{dup 0 gt{
/overprint_flag true def}if outl_color exch get_devicen_color_spec
overprint_flag set_current_color{matrix currentmatrix $ptm concat @gs stroke
@gr setmatrix}{@np exit}ifelse}for}{outl_color overprint_flag set_current_color
{matrix currentmatrix $ptm concat @gs stroke @gr setmatrix}{@np exit}ifelse
}ifelse}ifelse $SDF{$dsf $dsa $dsp @ss}if setmatrix}bd/s{@cp S}bd/B{@gs F @gr S
}bd/b{@cp B}bd/_E{5 array astore exch cvlit xd}bd/@cc{currentfile $dat
readhexstring pop}bd/@sm{/$ctm $ctm currentmatrix def}bd/@E{/Bbury xd/Bburx xd
/Bblly xd/Bbllx xd}bd/@c{@cp}bd/@P{/$fil 3 def/$Psn xd/$Psc xd array astore
/$Prm xd}bd/tcc{@cc}def/@B{@gs S @gr F}bd/@b{@cp @B}bd/@sep{CurrentInkName_5
(Composite)eq{/$ink_5 -1 def}{CurrentInkName_5(Cyan)eq{/$ink_5 0 def}{
CurrentInkName_5(Magenta)eq{/$ink_5 1 def}{CurrentInkName_5(Yellow)eq{/$ink_5 2
def}{CurrentInkName_5(Black)eq{/$ink_5 3 def}{/$ink_5 4 def}ifelse}ifelse}
ifelse}ifelse}ifelse}bd/@whi{@gs -72000 dup m -72000 72000 l 72000 dup l 72000
-72000 l @cp 1 SetGry fill @gr}bd/@neg{[{1 exch sub}/exec cvx currenttransfer
/exec cvx]cvx settransfer @whi}bd/deflevel 0 def/@sax{/deflevel deflevel 1 add
def}bd/@eax{/deflevel deflevel dup 0 gt{1 sub}if def deflevel 0 gt{/eax load}{
eax}ifelse}bd/eax{{exec}forall}bd/@rax{deflevel 0 eq{@rs @sv}if}bd systemdict
/pdfmark known not{/pdfmark/cleartomark ld}if/wclip{1 $fm eq{clip}{eoclip}
ifelse}bd level2{/setregcolor{/neg_flag exch def[/Separation/All/DeviceCMYK{
dup dup dup}]setcolorspace 1.0 neg_flag sub setcolor}bd}{/setregcolor{1 exch
sub dup dup dup setcmykcolor}bd}ifelse/CorelTintTransformFunction{
/colorantSpecArray exch def/nColorants colorantSpecArray length 4 idiv def
/inColor nColorants 1 add 1 roll nColorants array astore def/outColor 4 array
def 0 1 3{/nOutInk exch def 1 0 1 nColorants 1 sub{dup inColor exch get exch 4
mul nOutInk add colorantSpecArray exch get mul 1 exch sub mul}for 1 exch sub
outColor nOutInk 3 -1 roll put}for outColor aload pop}bind def
% Copyright (c)1992-2005 Corel Corporation
% All rights reserved.     v13 r0.0
/@ii{concat 3 index 3 index m 3 index 1 index l 2 copy l 1 index 3 index l 3
index 3 index l clip pop pop pop pop}bd/@i{@sm @gs @ii 6 index 1 ne{/$frg true
def pop pop}{1 eq{bmp_fill_fg_color $O set_current_color/$frg xd}{/$frg false
def}ifelse 1 eq{@gs $ctm setmatrix F @gr}if}ifelse @np/$ury xd/$urx xd/$lly xd
/$llx xd/$bts xd/$hei xd/$wid xd/$dat $wid $bts mul 8 div ceiling cvi string
def $bkg $frg or{$SDF{$SCF $SCA $SCP @ss}if $llx $lly Tl $urx $llx sub $ury
$lly sub scale $bkg{fill_color set_current_color pop}if $wid $hei abs $bts 1 eq
{$bkg}{$bts}ifelse[$wid 0 0 $hei neg 0 $hei 0 gt{$hei}{0}ifelse]/tcc load $bts
1 eq{imagemask}{image}ifelse $SDF{$dsf $dsa $dsp @ss}if}{$hei abs{tcc pop}
repeat}ifelse @gr $ctm setmatrix}bd/@I{@sm @gs @ii @np/$ury xd/$urx xd/$lly xd
/$llx xd/$ncl xd/$bts xd/$hei xd/$wid xd $ngx $llx $lly Tl $urx $llx sub $ury
$lly sub scale $wid $hei abs $bts[$wid 0 0 $hei neg 0 $hei 0 gt{$hei}{0}ifelse
]/$dat $wid $bts mul $ncl mul 8 div ceiling cvi string def $msimage false eq
$ncl 1 eq or{/@cc load false $ncl ColorImage}{$wid $bts mul 8 div ceiling cvi
$ncl 3 eq{dup dup/$dat1 exch string def/$dat2 exch string def/$dat3 exch string
def/@cc1 load/@cc2 load/@cc3 load}{dup dup dup/$dat1 exch string def/$dat2 exch
string def/$dat3 exch string def/$dat4 exch string def/@cc1 load/@cc2 load
/@cc3 load/@cc4 load}ifelse true $ncl ColorImage}ifelse $SDF{$dsf $dsa $dsp
@ss}if @gr $ctm setmatrix}bd/@cc1{currentfile $dat1 readhexstring pop}bd/@cc2{
currentfile $dat2 readhexstring pop}bd/@cc3{currentfile $dat3 readhexstring pop
}bd/@cc4{currentfile $dat4 readhexstring pop}bd/$msimage false def/COMP 0 def
/MaskedImage false def/bImgDeviceN false def/nNumInksDeviceN 0 def
/sNamesDeviceN[]def/tint_params[]def level2{/@I_2{@sm @gs @ii @np/$ury xd/$urx
xd/$lly xd/$llx xd/$ncl xd/$bts xd/$hei xd/$wid xd/$dat $wid $bts mul $ncl mul
8 div ceiling cvi string def $ngx $ncl 1 eq{/DeviceGray}{$ncl 3 eq{/DeviceRGB}
{/DeviceCMYK}ifelse}ifelse setcolorspace $llx $lly Tl $urx $llx sub $ury $lly
sub scale 8 dict begin/ImageType 1 def/Width $wid def/Height $hei abs def
/BitsPerComponent $bts def/Decode $ncl 1 eq{[0 1]}{$ncl 3 eq{[0 1 0 1 0 1]}{[0
1 0 1 0 1 0 1]}ifelse}ifelse def/ImageMatrix[$wid 0 0 $hei neg 0 $hei 0 gt
{$hei}{0}ifelse]def/DataSource currentfile/ASCII85Decode filter COMP 1 eq
{/DCTDecode filter}{COMP 2 eq{/RunLengthDecode filter}if}ifelse def currentdict
end image $SDF{$dsf $dsa $dsp @ss}if @gr $ctm setmatrix}bd}{/@I_2{}bd}ifelse
level2{/@I_2D{@sm @gs @ii @np/$ury xd/$urx xd/$lly xd/$llx xd/$ncl xd/$bts xd
/$hei xd/$wid xd $ngx/scanline $wid $bts mul $ncl mul 8 div ceiling cvi string
def/readscanline{currentfile scanline readhexstring pop}bind def level3{[
/DeviceN sNamesDeviceN/DeviceCMYK{tint_params CorelTintTransformFunction}]
setcolorspace $llx $lly Tl $urx $llx sub $ury $lly sub scale 8 dict begin
/ImageType 1 def/Width $wid def/Height $hei abs def/BitsPerComponent $bts def
/Decode[nNumInksDeviceN{0 1}repeat]def/ImageMatrix[$wid 0 0 $hei neg 0 $hei 0
gt{$hei}{0}ifelse]def/DataSource{readscanline}def currentdict end image}{
/scanline_height $lly $ury sub 1 sub $hei div def/plate_scanline $wid string
def/cmyk_scanline $wid 4 mul string def is_distilling is_rip_separation or{
/bSimDeviceN true def}{/bSimDeviceN false def}ifelse/scanline_img_dict 8 dict
begin/ImageType 1 def/Width $wid def/Height 1 def/BitsPerComponent $bts def
/Decode bSimDeviceN{[0 1]}{[0 1 0 1 0 1 0 1]}ifelse def/ImageMatrix[$wid 0 0 1
neg 0 1]def/DataSource bSimDeviceN{plate_scanline}{cmyk_scanline}ifelse def
currentdict end def 0 1 $hei 1 sub{@gs/nScanIndex exch def readscanline pop
/$t_lly $ury $lly scanline_height nScanIndex mul sub sub ceiling cvi def
/$t_ury $t_lly scanline_height sub ceiling cvi def bSimDeviceN{0 1 $ncl 1 sub{
@gs/nInkIndex exch def 0 1 plate_scanline length 1 sub{dup $ncl mul nInkIndex
add scanline exch get plate_scanline 3 1 roll put}for[0 1 $ncl 1 sub{nInkIndex
eq{1.0}{0.0}ifelse}for]/sepTintTransformParams exch def[/Separation
sNamesDeviceN nInkIndex get/DeviceCMYK{sepTintTransformParams aload pop
tint_params CorelTintTransformFunction @tc_5}]setcolorspace $llx $t_lly Tl $urx
$llx sub $t_ury $t_lly sub scale nInkIndex 0 eq currentoverprint not and{false
setoverprint}{true setoverprint}ifelse scanline_img_dict image @gr}for}{0 1
$wid 1 sub{dup $ncl mul scanline exch $ncl getinterval 0 1 $ncl 1 sub{2 copy
get 255 div 3 1 roll pop}for pop tint_params CorelTintTransformFunction 5 -1
roll cmyk_scanline exch 0 1 3{3 1 roll 2 copy 5 -1 roll dup 8 exch sub index
255 mul cvi 3 1 roll exch 4 mul add exch put}for 6 rp}for/DeviceCMYK
setcolorspace $llx $t_lly Tl $urx $llx sub $t_ury $t_lly sub scale
scanline_img_dict image}ifelse @gr}for}ifelse $SDF{$dsf $dsa $dsp @ss}if @gr
$ctm setmatrix}bd}{/@I_2D{}bd}ifelse/@I_3{@sm @gs @ii @np/$ury xd/$urx xd/$lly
xd/$llx xd/$ncl xd/$bts xd/$hei xd/$wid xd/$dat $wid $bts mul $ncl mul 8 div
ceiling cvi string def $ngx bImgDeviceN{[/DeviceN sNamesDeviceN/DeviceCMYK{
tint_params CorelTintTransformFunction}]}{$ncl 1 eq{/DeviceGray}{$ncl 3 eq
{/DeviceRGB}{/DeviceCMYK}ifelse}ifelse}ifelse setcolorspace $llx $lly Tl $urx
$llx sub $ury $lly sub scale/ImageDataDict 8 dict def ImageDataDict begin
/ImageType 1 def/Width $wid def/Height $hei abs def/BitsPerComponent $bts def
/Decode[$ncl{0 1}repeat]def/ImageMatrix[$wid 0 0 $hei neg 0 $hei 0 gt{$hei}{0}
ifelse]def/DataSource currentfile/ASCII85Decode filter COMP 1 eq{/DCTDecode
filter}{COMP 2 eq{/RunLengthDecode filter}if}ifelse def end/MaskedImageDict 7
dict def MaskedImageDict begin/ImageType 3 def/InterleaveType 3 def/MaskDict
ImageMaskDict def/DataDict ImageDataDict def end MaskedImageDict image $SDF
{$dsf $dsa $dsp @ss}if @gr $ctm setmatrix}bd/@SetMask{/$mbts xd/$mhei xd/$mwid
xd/ImageMaskDict 8 dict def ImageMaskDict begin/ImageType 1 def/Width $mwid def
/Height $mhei abs def/BitsPerComponent $mbts def/DataSource maskstream def
/ImageMatrix[$mwid 0 0 $mhei neg 0 $mhei 0 gt{$mhei}{0}ifelse]def/Decode[1 0]
def end}bd/@daq{dup type/arraytype eq{{}forall}if}bd/@BMP{/@cc xd UseLevel 3 eq
MaskedImage true eq and{7 -2 roll pop pop @I_3}{12 index 1 gt UseLevel 2 eq
UseLevel 3 eq or and{7 -2 roll pop pop bImgDeviceN{@I_2D}{@I_2}ifelse}{11 index
1 eq{12 -1 roll pop @i}{7 -2 roll pop pop @I}ifelse}ifelse}ifelse}bd
/disable_raster_output{/@BMP load/old_raster_func exch bind def/@BMP{8 rp/$ury
xd/$urx xd/$lly xd/$llx xd/$ncl xd/$bts xd/$hei xd/$wid xd/scanline $wid $bts
mul $ncl mul 8 div ceiling cvi string def 0 1 $hei 1 sub{currentfile scanline
readhexstring pop pop pop}for}def}bd/enable_raster_output{/old_raster_func
where{pop/old_raster_func load/@BMP exch bd}if}bd
end
%%EndResource
%%EndProlog
%%BeginSetup
wCorel3Dict begin
@BeginSysCorelDict
@ssa
1.00 setflat
/$fst 128 def
%%EndSetup

%%Page: 1 1
%%ViewingOrientation: 0 1 1 0
%LogicalPage: 1
%%BeginPageSetup
@sv
@sm
@sv
%%EndPageSetup
@rax %Note: Object
101.46132 315.74353 376.46079 616.59269 @E
/$fm 0 def
0 J 2 j 1145.915735705782900 setmiterlimit
[1.00000 3.00000 ] 0 d 0 R 0 @G
[ 1.00 0.00 0.00 0.00 1.00 null ] set_outline_color
0 1.99984 1.99984 0.00000 @w
258.34564 416.06249 m
259.58353 411.78217 L
258.24274 407.80063 L
257.46094 407.74337 L
257.46094 412.74340 L
256.46117 412.74340 L
256.46117 408.74343 L
252.50003 407.62091 L
252.46120 410.74356 L
251.46113 410.74356 L
251.46113 401.74356 L
249.06104 405.57118 L
243.75373 398.19600 L
242.46113 397.74331 L
241.91121 399.89339 L
241.57332 394.70655 246.30973 386.28000 248.69679 382.97906 C
251.08186 379.68094 267.62740 368.40643 255.60170 374.00627 C
260.66806 369.00312 L
258.46101 368.74346 L
260.94728 365.30646 L
260.10567 362.58208 265.87644 357.12482 270.46120 356.74328 C
269.72872 361.79461 L
270.40620 364.76447 L
263.54750 368.89002 L
265.15502 376.01376 276.76885 386.89540 277.46107 395.74346 C
278.71739 413.72334 L
278.86649 418.92548 276.43748 425.28387 276.46044 432.74296 C
276.48227 439.74170 276.46101 446.74413 276.46101 453.74343 C
276.27761 453.80466 L
276.27761 453.80466 L
276.46101 453.74343 L
271.40995 453.01096 L
271.46098 455.74356 L
269.46113 455.74356 L
270.96265 452.71474 270.15052 456.86466 270.46120 452.74337 C
270.46120 439.74340 L
267.75383 438.65065 266.46094 434.30542 266.46094 430.74340 C
266.46094 430.46929 267.15005 428.91619 267.46101 427.74350 C
262.82069 433.03011 L
263.61269 426.77660 L
259.92369 425.31562 262.70022 427.41014 260.46113 422.74346 C
261.40649 419.72230 L
260.31969 416.77058 L
258.51373 417.82876 L
258.34564 416.06249 L
208.46126 415.74331 m
210.90161 418.55131 213.35046 421.58409 214.51380 425.82898 C
216.46120 424.74331 L
216.15024 430.96365 215.71002 438.35726 217.10438 444.49228 C
217.13613 444.63061 L
217.52079 446.29002 218.00806 447.82214 218.42872 449.65077 C
224.46113 447.99335 L
233.54646 447.69061 L
232.51578 445.76447 L
233.46113 442.74331 L
233.67033 442.99644 L
233.67033 442.99644 L
231.58091 441.72539 L
230.46123 429.74334 L
230.46123 420.07266 225.88101 418.85065 222.46101 413.74346 C
223.80009 411.04346 223.15408 408.46706 224.46113 405.74353 C
223.79301 404.48069 222.46101 402.43691 222.46101 400.74350 C
222.46101 396.37247 225.57260 390.58044 228.23631 388.51852 C
233.73581 384.26117 233.06995 384.60501 237.68589 379.96838 C
246.35707 371.25893 248.07118 371.81934 254.11209 359.89002 C
251.46113 351.74353 L
244.78129 347.27046 250.82702 347.10746 240.63109 344.57329 C
235.46466 343.28920 232.97443 340.91206 232.48120 334.94428 C
246.46110 333.74353 L
251.89002 333.19814 253.00913 334.74331 257.46094 334.74331 C
260.71172 334.74331 258.21609 335.60986 262.72800 336.78000 C
261.60180 345.48066 L
266.46094 347.74328 L
267.15969 339.34932 269.35597 334.97376 275.46094 331.74340 C
277.70372 332.26583 277.76013 332.74346 280.46098 332.74346 C
287.27773 332.74346 283.87361 348.18406 283.46117 351.74353 C
283.23184 353.69461 280.48139 357.21553 278.82709 358.10929 C
270.63241 362.53672 277.59600 359.98129 272.46104 363.74343 C
276.70564 371.76520 280.19083 376.56624 284.44819 383.75631 C
286.49792 387.21770 298.46098 399.52913 298.46098 402.74334 C
298.46098 405.74353 L
298.46098 408.55946 298.02841 407.59512 296.46113 408.74343 C
297.18369 410.02980 297.30983 409.78375 297.16639 411.76602 C
299.46104 438.74334 L
299.60617 439.97896 305.88576 453.04724 306.94564 454.25877 C
310.81465 458.68139 312.79124 467.41521 316.46098 468.74353 C
316.46098 460.31216 316.26539 443.98602 322.46107 441.74353 C
322.46107 432.74353 L
322.46107 430.35165 327.28365 421.09795 328.40617 419.76454 C
327.46110 416.74337 L
331.27455 416.67194 L
332.94501 411.73682 L
332.46085 389.74337 L
332.46085 383.70643 335.01855 380.67194 334.55906 375.73228 C
333.46091 363.74343 L
332.08526 351.58422 326.46104 344.71616 326.46104 334.74331 C
326.46104 331.97953 323.20517 329.91137 321.63194 328.71458 C
320.46094 320.74328 L
323.81660 319.94022 325.28353 319.13036 328.61509 320.91392 C
332.46085 317.74337 L
334.82608 318.91578 336.90529 318.74343 339.46101 318.74343 C
341.50337 318.74343 346.46088 321.98343 346.46088 324.74353 C
346.46088 327.83272 343.46098 328.05723 343.46098 331.74340 C
343.46098 335.06192 345.46082 333.83112 345.46082 335.74337 C
345.46082 340.60054 339.65036 347.07345 340.57644 356.73364 C
341.46085 370.74331 L
341.89455 375.91625 343.33058 373.89090 343.46098 379.74331 C
346.05213 381.64195 345.97843 381.63657 346.44359 385.74539 C
347.46094 396.74353 L
347.89805 400.46258 344.92932 402.55058 343.46098 404.74346 C
344.51008 409.24687 347.17181 416.69461 346.47817 422.74545 C
345.81572 433.83430 L
343.56643 444.89395 L
345.46082 453.74343 L
345.46082 467.74346 L
345.46082 473.68517 350.46085 478.78356 350.46085 484.74340 C
351.51364 489.82876 L
353.38535 488.78589 L
355.27436 491.67184 L
356.46094 488.74337 L
354.92995 485.65531 354.99883 480.79049 356.46094 477.74353 C
355.64683 474.24756 355.46088 471.30548 355.46088 467.74346 C
357.46101 467.74346 L
357.68296 458.71002 L
356.46094 449.74346 L
352.62170 448.71817 351.37304 446.65824 350.51386 442.65798 C
352.81616 443.61496 L
350.46085 436.74350 L
352.46098 436.74350 L
351.46091 420.74334 L
353.46104 420.74334 L
353.60476 427.20180 356.55024 429.12454 360.46091 431.74346 C
360.69959 442.45389 369.46091 444.19691 369.46091 451.74331 C
369.51364 456.82894 L
371.46104 455.74356 L
371.46104 458.74346 L
373.39370 458.72164 L
370.49329 468.32060 L
376.46079 468.74353 L
373.66611 474.02532 370.46098 474.21156 370.46098 481.74350 C
370.46098 483.94913 369.94110 485.75027 369.58139 487.88844 C
372.46082 485.74346 L
371.31506 490.66157 372.03194 493.12715 368.46085 495.74353 C
368.46085 499.74350 L
367.13650 500.71380 357.84255 511.30403 356.86063 513.14315 C
355.59354 515.51603 348.19795 529.20340 347.46094 529.74340 C
347.25798 538.85962 339.51373 553.09266 334.70277 557.98526 C
331.99512 560.73855 321.46101 582.11036 321.46101 585.74353 C
321.46101 589.74350 L
321.46101 598.51474 311.23361 605.10954 307.46098 610.74340 C
305.81575 610.74340 304.31622 610.76154 302.68318 610.96564 C
298.38954 614.92989 L
295.46107 613.74359 L
294.33515 618.44740 293.43203 616.18082 290.46104 614.99339 C
287.19836 614.83039 283.70211 615.00586 280.57606 614.05767 C
274.46117 615.74343 L
274.46117 613.74359 L
272.67931 613.68633 L
271.46098 609.74334 L
267.20249 612.13635 261.51307 609.86948 257.47058 607.79140 C
251.51584 608.76454 L
252.57175 605.59398 L
237.51581 594.76450 L
238.46117 591.74334 L
235.71043 591.70365 L
234.46120 583.74340 L
234.92580 583.74340 L
234.92891 583.57984 L
230.95814 582.70564 229.32595 578.45707 226.87030 575.33443 C
224.38772 572.17776 221.65257 571.18082 218.84173 568.36290 C
216.18709 565.70202 213.12283 564.06104 209.59795 562.60658 C
204.50268 560.50469 203.00428 557.66409 200.46104 556.74340 C
199.96951 554.60466 L
199.93861 554.56951 L
197.46113 553.74350 L
197.46113 550.74359 L
194.99046 550.08369 185.46123 536.30957 185.46123 533.74337 C
185.46123 530.34831 185.32517 524.30287 181.46126 522.74353 C
181.46126 517.74350 L
177.51600 517.77269 L
175.55556 521.72646 L
178.46107 539.74346 L
180.46120 539.74346 L
180.46120 535.74350 L
181.19424 535.78006 L
182.46104 544.74350 L
184.46117 544.74350 L
184.46117 541.74331 L
185.46123 541.74331 L
185.46123 549.74353 L
185.46123 553.56690 185.76822 550.10750 184.46117 552.74343 C
186.35046 555.46243 186.08258 555.69033 186.53584 559.73650 C
187.46107 572.74356 L
187.84063 576.80674 187.17846 575.14422 186.46129 575.74346 C
185.95899 575.31855 L
185.95899 575.31855 L
186.46129 575.74346 L
184.47874 579.49030 184.88183 581.56299 180.46120 582.74334 C
180.79172 586.71609 181.46126 585.15222 181.46126 587.74337 C
181.46126 591.39156 180.56409 590.12617 180.46120 594.74353 C
174.86674 596.04690 169.53874 605.74337 165.46110 605.74337 C
162.27468 605.81509 L
163.45219 608.77928 L
158.75178 607.95298 L
156.46110 611.74346 L
152.85600 610.78082 153.78661 611.65219 153.24520 607.39739 C
149.46123 609.74334 L
149.33282 607.09890 L
142.32756 604.74728 L
142.38964 598.93002 L
139.55953 597.78340 138.37635 597.57732 135.41584 598.11477 C
114.46129 595.74359 L
110.83890 595.30082 101.46132 582.65263 101.46132 581.74356 C
101.46132 578.92734 101.89389 579.89197 103.46117 578.74337 C
103.46117 574.74340 L
105.83660 573.48652 110.27282 570.74343 113.46123 570.74343 C
119.46132 570.74343 L
121.74860 570.74343 127.22910 566.58359 128.66967 564.62088 C
121.46117 553.74350 L
120.80098 550.11883 L
114.51402 537.65802 L
116.46113 538.74340 L
116.46113 535.84299 116.74431 533.41767 115.46135 530.74346 C
116.91298 528.15855 116.74857 526.24998 115.27483 523.67187 C
116.58359 520.70457 L
115.51408 516.65811 L
117.93628 517.61877 L
115.71137 509.74356 L
117.53291 494.55694 L
120.46139 495.74353 L
120.46139 491.74356 L
122.43203 492.65490 124.46135 493.35562 124.46135 489.74343 C
124.51408 482.65795 L
126.46120 483.74334 L
126.46120 480.74343 L
128.46132 480.74343 L
128.46132 483.74334 L
130.68964 483.14835 131.46123 483.50976 131.46123 480.74343 C
131.51395 477.65792 L
133.68614 478.70050 L
132.67729 469.39720 L
136.02444 471.22980 L
139.44019 468.79824 L
142.46135 469.74331 L
142.58154 463.59836 L
145.46126 465.74334 L
145.46126 467.74346 L
146.54863 468.84444 L
146.54863 468.84444 L
145.46126 467.74346 L
148.54819 467.74346 143.46113 460.77732 143.46113 458.74346 C
143.46113 455.92724 143.89370 456.89187 145.46126 455.74356 C
145.82835 460.15342 145.89780 461.79184 148.75342 462.32929 C
153.46970 454.73046 L
160.42535 458.73439 L
161.46113 453.74343 L
166.84469 453.29556 164.39102 451.74331 166.46117 451.74331 C
167.74554 451.74331 170.58983 455.74072 171.46120 456.74334 C
171.46120 451.74331 L
173.46132 451.74331 L
173.53276 453.92995 L
176.06154 453.13710 L
181.46126 458.74346 L
181.33455 458.77550 L
181.33455 458.77550 L
181.46126 458.74346 L
182.29465 459.91020 L
182.46104 456.74334 L
185.11795 459.99439 L
186.62145 457.32529 187.46107 455.36854 187.46107 451.74331 C
187.46107 447.36661 185.43317 448.09228 185.46123 443.74337 C
185.19732 427.74180 L
185.48532 424.01282 184.80274 425.84683 184.46117 421.74340 C
186.40828 422.82879 L
185.19420 413.78003 L
187.46107 413.74346 L
187.35817 409.12611 186.46129 410.39150 186.46129 406.74331 C
186.46129 404.40387 186.16167 404.15641 185.46123 402.74334 C
187.94750 399.30661 L
187.23090 386.76813 L
186.98712 382.31603 189.46120 381.01153 189.46120 376.74340 C
189.46120 367.45909 186.31389 354.60170 183.14022 348.06444 C
180.95839 343.56954 178.73263 341.22132 177.07209 337.13235 C
175.30809 332.78939 174.21874 328.74350 168.46129 328.74350 C
164.26148 328.74350 159.19030 325.32576 157.46117 322.74340 C
158.64775 319.81493 L
164.65408 319.22816 161.79109 315.74353 168.46129 315.74353 C
176.46123 315.74353 L
183.19436 315.74353 184.64882 317.62233 189.46120 318.74343 C
188.43817 326.73969 L
190.00772 329.04964 192.86419 330.82583 190.46126 333.74353 C
186.49049 331.68869 L
184.51106 332.89342 L
182.32129 339.69713 L
184.26104 341.94331 L
185.67014 346.99266 L
187.01121 344.59342 L
189.70214 353.67591 L
190.46126 353.74337 L
190.46126 344.74337 L
191.46104 344.74337 L
191.46104 348.74334 L
192.46110 348.74334 L
192.46110 341.74346 L
193.46117 341.74346 L
193.46117 345.74343 L
193.46117 353.54835 197.46113 357.92362 197.46113 359.74346 C
197.46113 365.74328 L
197.46113 374.76680 205.46107 379.40031 205.46107 391.74350 C
205.46107 395.60117 204.46101 393.98117 204.46101 398.74337 C
204.46101 402.21751 206.46113 400.26954 206.46113 403.74340 C
206.46113 410.74356 L
208.46126 410.74356 L
208.46126 415.74331 L
S

@rax %Note: Object
87.54746 297.64630 87.54860 647.56630 @E
/$fm 0 def
0 J 0 j 22.925585626053735 setmiterlimit
[] 0 d 0 R 0 @G
[ 1.00 0.00 0.00 0.00 1.00 null ] set_outline_color
0 1.99984 1.99984 0.00000 @w
87.54803 297.64630 m
87.54803 644.82633 L
S
@j
[ 1.00 0.00 0.00 0.00 1.00 null ] set_outline_color
[ 1.00 0.00 0.00 0.00 1.00 null ] set_fill_color
0 @g
0 @G
[] 0 d 0 J 0 j
0 R 0 O
0 2.00013 2.00013 0 @w
82.43178 638.48580 m
87.54803 646.37830 L
92.66825 638.48580 L
S
@J

@rax %Note: Object
87.54803 297.64573 389.31279 297.64687 @E
/$fm 0 def
0 J 0 j 22.925585626053735 setmiterlimit
[] 0 d 0 R 0 @G
[ 1.00 0.00 0.00 0.00 1.00 null ] set_outline_color
0 1.99984 1.99984 0.00000 @w
87.54803 297.64630 m
386.57282 297.64630 L
S
@j
[ 1.00 0.00 0.00 0.00 1.00 null ] set_outline_color
[ 1.00 0.00 0.00 0.00 1.00 null ] set_fill_color
0 @g
0 @G
[] 0 d 0 J 0 j
0 R 0 O
0 2.00013 2.00013 0 @w
380.23228 302.76255 m
388.12479 297.64630 L
380.23228 292.52608 L
S
@J

%%PageTrailer
@rs
@rs
%%Trailer
@EndSysCorelDict
end
%%DocumentSuppliedResources: procset wCorel3Dict 3.0 0
%%EOF

