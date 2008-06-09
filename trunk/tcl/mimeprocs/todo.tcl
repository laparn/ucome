# extension for todo
set conf(extension.todo) todo

lappend filetype_list todo

# And now all procedures for todo. How to translate into a comp,
namespace eval todo {
	regsub -all "::" [namespace current] {} local_filetype
	global DOMP_PROCEDURES
	eval $DOMP_PROCEDURES
	proc new { current_env current_conf dirname filename filetype ON_EXTENSION_FLAG } {
		variable local_filetype
		fas_debug "${local_filetype}::new - _env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf

		# I will just create a particular name here ?
		global _cgi_uservar
		variable local_conf
		set _cgi_uservar(comp.####) "[file join [fas_name_and_dir::get_comp_dir fas_env domp] $local_conf(comp)]"
		set now [clock seconds]
		set month_list [list january february march april may june july august september november december]
		set _cgi_uservar(comp.date.content) "[clock format $now -format "%d"] [translate [lindex $month_list [expr [string trimleft [clock format $now -format "%m"] 0] - 1]]] [clock format $now -format "%Y"]"

		# I create a name for the file :
		# yearmonthday-hhmmss-user.todo
		set filename "[clock format $now -format "%Y%m%d-%H%M%S"]-[fas_user::who_am_i].${local_filetype}"

		comp::new fas_env fas_conf $dirname $filename ${local_filetype} $ON_EXTENSION_FLAG
	}
}
