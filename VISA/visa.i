/*$Id$*/

%perlcode %{
$Lab::VISA::VERSION="2.02";
%}

%module "Lab::VISA"

#define test 7;
%{
#include "visa.h"
%}

%include "visadef.i"
%include "typemaps.i"


%define %viread_output(TYPEMAP, SIZE, REALSIZE)
%typemap(in) (TYPEMAP, SIZE){
    $2 = ($2_ltype)SvIV($input);
    $1 = ($1_ltype) malloc($2 + 1);
}
%typemap(argout) (TYPEMAP, SIZE, REALSIZE){
    if (argvi >= items){
         EXTEND(sp, 1);
    }

    $result = sv_newmortal();
    sv_setpvn($result,(char *)$1, $3);
    argvi++;
    free($1);
}
%enddef

%define %cstring_bounded_output(TYPEMAP, MAX)
%typemap(in,numinputs=0) TYPEMAP(char temp[MAX+1]) {
   $1 = ($1_ltype) temp;
}
%typemap(argout) TYPEMAP {
    if (argvi >= items){
         EXTEND(sp, 1);
    }

    $result = sv_newmortal();
    sv_setpv($result,(char *)$1);
    argvi++;
}
%enddef

extern ViStatus _VI_FUNC viOpenDefaultRM(ViSession *OUTPUT);
extern ViStatus _VI_FUNC viOpen(ViSession sesn, ViRsrc name, ViAccessMode mode, ViUInt32 timeout, ViSession *OUTPUT);

extern ViStatus _VI_FUNC viSetAttribute(ViObject vi, ViAttr attrName, ViAttrState attrValue);
extern ViStatus _VI_FUNC viGetAttribute(ViObject vi, ViAttr attrName, void *OUTPUT);

%apply char* { ViBuf };
extern ViStatus _VI_FUNC viWrite (ViSession vi, ViBuf buf, ViUInt32 cnt, ViUInt32 *OUTPUT);
extern ViStatus _VI_FUNC viClose (ViObject vi);

extern ViStatus viClear(ViSession vi);

%viread_output(ViPBuf buf, ViUInt32 cnt, ViUInt32 *OUTPUT);
extern ViStatus _VI_FUNC viRead (ViSession vi, ViPBuf buf, ViUInt32 cnt, ViUInt32 *OUTPUT);

%cstring_bounded_output(ViPChar instrDesc, 512);
extern ViStatus viFindRsrc(ViSession vi, ViString expr, ViFindList *OUTPUT, ViUInt32 *OUTPUT, ViPChar instrDesc);
extern ViStatus viFindNext(ViFindList findList, ViPChar instrDesc);
