/*$Id$
$VERSION=sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
*/

%module VISA
%{
#include "/usr/local/vxipnp/linux/include/visa.h"
%}

%include "visadef.i"
%include "typemaps.i"

/*%include "cstring.i"*/
%define %cstring_output_maxsize(TYPEMAP, SIZE)
%typemap(in) (TYPEMAP, SIZE){
    $2 = ($2_ltype)SvIV($input);
    $1 = ($1_ltype) malloc($2 + 1);
}
%typemap(argout) (TYPEMAP, SIZE){
    if (argvi >= items){
         EXTEND(sp, 1);
    }

    $result = sv_newmortal();
    sv_setpv($result,(char *)$1);
    argvi++;
    free($1);
}
%enddef

%define %cstring_bounded_output(TYPEMAP, MAX)
%typemap(ignore) TYPEMAP(char temp[MAX+1]) {
   $1 = ($1_ltype) temp;
}
%typemap(argout,fragment="t_output_helper") TYPEMAP {
    if (argvi >= items){
         EXTEND(sp, 1);
    }

    $result = sv_newmortal();
    sv_setpv($result,(char *)$1);
    argvi++;
    free($1);
}
%enddef

extern ViStatus _VI_FUNC viOpenDefaultRM(ViSession *OUTPUT);
extern ViStatus _VI_FUNC viOpen(ViSession sesn, ViRsrc name, ViAccessMode mode, ViUInt32 timeout, ViSession *OUTPUT);

extern ViStatus _VI_FUNC viSetAttribute(ViObject vi, ViAttr attrName, ViAttrState attrValue);
extern ViStatus _VI_FUNC viGetAttribute(ViObject vi, ViAttr attrName, void *OUTPUT);

extern ViStatus _VI_FUNC viWrite (ViSession vi, ViBuf  buf, ViUInt32 cnt, ViUInt32 *OUTPUT);
extern ViStatus _VI_FUNC viClose (ViObject vi);

extern ViStatus viClear(ViSession vi);

%cstring_output_maxsize(ViPBuf buf, ViUInt32 cnt);
extern ViStatus _VI_FUNC viRead (ViSession vi, ViPBuf buf, ViUInt32 cnt, ViUInt32 *OUTPUT);

%cstring_output_maxsize(ViString expr, 512);
extern ViStatus viFindRsrc(ViSession vi, ViString expr, ViFindList *OUTPUT, ViUInt32 *OUTPUT, ViChar *OUTPUT);