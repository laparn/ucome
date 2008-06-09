# extension for domp
set conf(extension.domp) domp

lappend filetype_list domp

# And now all procedures for todo. How to translate into a comp,
namespace eval domp {
	regsub -all "::" [namespace current] {} local_filetype
	global DOMP_PROCEDURES
	eval $DOMP_PROCEDURES
}
