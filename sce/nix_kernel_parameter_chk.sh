#!/usr/bin/env bash

#
# CIS-CAT Script Check Engine
#
# Name         Date       Description
# -------------------------------------------------------------------
# E. Pinnell   04/21/21   Check kernel parameter
# E. Pinnell   12/03/21   Modified to deal with potential white space in the XCCDF_VALUE_REGEX variable
# E. Pinnell   12/20/21   Modified to correct false positive and potential false negative
# E. Pinnell   01/20/22   Modified to simplify check and improve output
#

krp="" pafile="" fafile=""
kpname=$(printf "%s" "$XCCDF_VALUE_REGEX" | awk -F= '{print $1}' | xargs)
kpvalue=$(printf "%s" "$XCCDF_VALUE_REGEX" | awk -F= '{print $2}' | xargs)
searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf"
krp="$(sysctl "$kpname" | awk -F= '{print $2}' | xargs)"
pafile="$(grep -Psl -- "^\h*$kpname\h*=\h*$kpvalue\b\h*(#.*)?$" $searchloc)"
# fafile="$(grep -Psl -- "^\h*$kpname\h*=\h*((?!\b$kpvalue\b).)*$" $searchloc)"
fafile="$(grep -s -- "^\s*$kpname" $searchloc | grep -Pv -- "\h*=\h*$kpvalue\b\h*" | awk -F: '{print $1}')"

# If the regex matched, output would be generated. If so, we pass
if [ "$krp" = "$kpvalue" ] && [ -n "$pafile" ] && [ -z "$fafile" ]; then
   echo "PASSED: 
   \"$kpname\" is set to \"$kpvalue\" in the running configuration and in:
   \"$pafile\"
   "
   exit "${XCCDF_RESULT_PASS:-101}"
else
   # print the reason why we are failing
   echo "FAILED:"
   [ "$krp" != "$kpvalue" ] && echo "\"$kpname\" is set to \"$krp\" in the running config"
   [ -n "$fafile" ] && echo "\"$kpname\" is set incorrectly in:
   \"$fafile\""
   [ -z "$pafile" ] && echo "\"$kpname = $kpvalue\" is not set in a kernel parameter configuration file"
   exit "${XCCDF_RESULT_FAIL:-102}"
fi