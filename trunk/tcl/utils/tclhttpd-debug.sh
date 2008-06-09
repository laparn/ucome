#!/bin/bash
# Script for starting tclhttpd from init.d
# If init.d does not start, please manually start this file as root
# and look in the file /tmp/httpd.st.txt, /tmp/httpd.st8017.txt, /tmp/ftpd.st.txt
# to understand what is not working.
echo $0
UCOMEDIR="`dirname $0`/../.."
TCLHTTPDHOME=${UCOMEDIR}/tclhttpd/bin
echo $TCLHTTPDHOME
su -c "${TCLHTTPDHOME}/httpd.tcl > /tmp/httpd.st.txt 2>&1 &" www-data
su -c "${TCLHTTPDHOME}/httpd.tcl -config ${TCLHTTPDHOME}/tclhttpd.rc-8017 > /tmp/httpd.st8017.txt 2>&1 &" www-data
FTPDHOME=`dirname $0`
su -c "${FTPDHOME}/ftpd-ucome > /tmp/ftpd.st.txt 2>&1 &" www-data
# Start of OO by www-data


