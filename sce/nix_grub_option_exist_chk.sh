#!/usr/bin/env sh

#
# CIS-CAT Script Check Engine
#
# Name         Date       Description
# -------------------------------------------------------------------
# E. Pinnell   04/09/21   Check grub options exists
# E. Pinnell   07/27/21   Modified to correct error and simplify script
# E. Pinnell   12/17/21   Modified to simplify and leverage grep -P

output="" grubfile="" passing=""

grubfile=$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -Pl -- '^\h*(kernelopts=|linux|kernel)' {} \;)

if [ -f "$grubfile" ]; then
	! grep -P -- "^\h*(kernelopts=|linux|kernel).*$" "$grubfile" | grep -Pvq -- "\b$XCCDF_VALUE_REGEX\b" && passing=true
	output="$(grep -P -- "^\h*(kernelopts=|linux|kernel).*$" "$grubfile" | grep -P -- "\b$XCCDF_VALUE_REGEX\b")"
fi

# If passing is true we pass
if [ "$passing" = true ] ; then
	echo "PASSED
	\"$grubfile\" contains:
	$output"
	exit "${XCCDF_RESULT_PASS:-101}"
else
	# print the reason why we are failing
	echo "FAILED:
	\"$grubfile\" doesn't contain: \"$XCCDF_VALUE_REGEX\""
	exit "${XCCDF_RESULT_FAIL:-102}"
fi