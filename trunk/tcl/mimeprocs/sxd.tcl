# extension for openoffice
set conf(extension.sxd) sxd

lappend filetype_list sxd

# And now all procedures for todo. How to translate into a comp,
namespace eval sxd {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	set base_convert "/usr/local/OpenOffice.org1.1.0/program/python ${FAS_PROG_ROOT}/utils/sxdconvert.py"
	set local_conf(convert_html) "${base_convert} --html"
	set local_conf(convert_pdf) "${base_convert} --pdf"
	set local_conf(convert_txt) "${base_convert} "
	set local_conf(ootype) "sxd"

	global OPENOFFICE_PROCEDURES
	eval $OPENOFFICE_PROCEDURES

}
