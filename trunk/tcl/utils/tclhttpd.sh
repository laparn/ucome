#!/bin/bash
# Script for starting tclhttpd from init.d
echo $0
UCOMEDIR="`dirname $0`/../.."
TCLHTTPDHOME=${UCOMEDIR}/tclhttpd/bin
echo $TCLHTTPDHOME
su -c "${TCLHTTPDHOME}/httpd.tcl > /dev/null 2>&1 &" www-data
su -c "${TCLHTTPDHOME}/httpd.tcl -config ${TCLHTTPDHOME}/tclhttpd.rc-8017 > /dev/null 2>&1 &" www-data
FTPDHOME=`dirname $0`
su -c "${FTPDHOME}/ftpd-ucome > /dev/null 2>&1 &" www-data
# Start of OO by www-data


