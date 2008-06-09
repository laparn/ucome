#!/usr/bin/tclsh
# vim: set syntax=tcl:

############### FILE USED FOR COMMAND LINE TESTING
set test "/any/index.html"
##################################################

# ROOT where all documents are to be found
# All files will be defined relatively to this root.
# It is not allowed for any file to refer outside.
# 
set FAS_VIEW_CGI ucome.cgi
set FAS_UPLOAD_CGI $FAS_VIEW_CGI

if { [file readable conf.tcl] } {
	source conf.tcl
} else {
	set ROOT /tmp/ucometest

	# FAS_PROG_ROOT is the directory where all tcl 
	# procedures are stored
	set FAS_PROG_ROOT /home/ludo/source/mana/tcl
	set FAS_VIEW_URL /cgi-bin/ucometest/${FAS_VIEW_CGI}
}

############### SOURCING OF ALL PROCEDURES
############### NORMALLY NOTHING TO CHANGE FROM HERE
#package require profiler
#::profiler::init

if { [catch { package require cgi }] } {
	source ${FAS_PROG_ROOT}/cgi.tcl
}
package require md5

source ${FAS_PROG_ROOT}/fas_debug_procedures.tcl
source ${FAS_PROG_ROOT}/fas_main_log.tcl
source ${FAS_PROG_ROOT}/fas_basic_proc.tcl
source ${FAS_PROG_ROOT}/atemt.tcl
source ${FAS_PROG_ROOT}/fas_env.tcl
source ${FAS_PROG_ROOT}/fas_name_and_dir.tcl
source ${FAS_PROG_ROOT}/fas_menu.tcl
source ${FAS_PROG_ROOT}/fas_display.tcl
source ${FAS_PROG_ROOT}/fas_display_error.tcl
source ${FAS_PROG_ROOT}/fas_session.tcl
source ${FAS_PROG_ROOT}/fas_depend.tcl
source ${FAS_PROG_ROOT}/fas_user.tcl
source ${FAS_PROG_ROOT}/fas_openoffice.tcl
source ${FAS_PROG_ROOT}/fas_init.tcl
source ${FAS_PROG_ROOT}/fas_domp.tcl
source ${FAS_PROG_ROOT}/fas_stat.tcl
source ${FAS_PROG_ROOT}/mimeprocs/binary.tcl
source ${FAS_PROG_ROOT}/mimeprocs/not_binary.tcl
source ${FAS_PROG_ROOT}/fas_extension.tcl
source ${FAS_PROG_ROOT}/fas_cache.tcl

# source files for internationalization
foreach file [glob -nocomplain ${FAS_PROG_ROOT}/i18n/*.tcl ] {
	source $file
}

# All source files for handling different file types are source hereunder
#foreach file [glob -nocomplain ${FAS_PROG_ROOT}/mimeprocs/*.tcl ] {
#	source $file
#}

source ${FAS_PROG_ROOT}/fas_debug.tcl
##################################################
# Just to say that we are not here displaying a comp
set IN_COMP 0
set ERROR_LOOP 0

cgi_eval {
	# Getting all cgi POST and GET variables
	cgi_input "file=$test"

	init_debug
	fas_stat::init
	
	set file [fas_get_value file -noe -nos -default "$test"]
	set _cgi_uservar(file) $file
	fas_debug "fas_view.tcl - file -> $file"
	# I should do something here to ensure that file is within the tree
	# some cleaning procedure to avoid any attack to the file system.
	set file [add_root $file]
	# I remove all .. of the filename, and check that
	# it stays under $ROOT
	set file [normalise $file]

	# Getting the action, default is view
	set action [fas_get_value action -noe -nos -default "view"]
	# I use an image for upload, then action is upload.xxxx.yyyy
	if { [regexp {^upload.*$} $action match] } {
		set action upload
	}
	set _cgi_uservar(action) "$action"
	fas_debug "fas_view.tcl - action -> $action"

	# Put all cgi var in the debug
	debug_cgi_uservar

	if { ![check_root $file] } {
		not_binary::content_display fashtml "<html><head><title>[translate "Error in "] ${FAS_VIEW_CGI}</title><body>[translate "You are not allowed to access this file"]<br></body></html>"
	} else {
		# now I extract the environment associated with the file
		read_full_env $file fas_env
		# Then I can get the session
		if { [catch { fas_session::open_session fas_env } error_string ] } {
			fas_display_error $error_string fas_env
		}
		# So from there, I have the following available arrays :
		#   conf : all configuration info for the program
		#   fas_env : variables associated with the current file
		#   fas_session::session : session informations
		#   _cgi_uservar : all variable imported
		#   _cgi_cookie : all cookies imported
	
		# Getting the current language
		international::init_language [fas_get_value language -default en]

		# I extract the filetype from the file extension
		all_extensions
		set filetype [guess_filetype $file conf fas_env]

		# Who is asking for the file
		set current_user [fas_user::find_user_name]

		fas_stat::append_stat

		# I am going to test if this action is or not allowed
		if { ![fas_user::allowed_action $file $action fas_env] } {
			fas_display_error "[translate "Sorry, you are not allowed to "] [translate $action] $file" fas_env
		} else {
			# I try to see if the result exists or not
			# This is a global first level check for the final file
			# Are the full dependencies or not met
			if { [fas_depend::check_complete_dependencies $file fas_env] } {
				# and now I display
				# Does not match then, I work out the file
				# All source files for handling different file types are source hereunder
				foreach src [glob -nocomplain ${FAS_PROG_ROOT}/mimeprocs/*.tcl ] {
					source $src
				}
				display_file $filetype $file fas_env conf
			} else {
				set final_filetype [fas_depend::get_final_filetype fas_env $file]
				if { $final_filetype == "" } {
					# Unknown output file, I work out the file
					# All source files for handling different file types are source hereunder
					foreach src [glob -nocomplain ${FAS_PROG_ROOT}/mimeprocs/*.tcl ] {
						source $src
					}
					display_file $filetype $file fas_env conf
				} else {
					set final_filename [fas_depend::get_final_filename]
					main_log "Using cache for direct display of [rm_root $file] in $final_filetype"
					# For get_real_filename to take directly
					# the cache_name, I need to have a list
					# with at least 2 elements.
					lappend conf(filetype_list) "$final_filetype" "$final_filetype" 
					if { $final_filename != "" } {
						binary::display_cache $final_filetype $final_filename fas_env 
					} else {
						# All source files for handling different file types are source hereunder
						foreach src [glob -nocomplain ${FAS_PROG_ROOT}/mimeprocs/*.tcl ] {
							source $src
						}
						display_file $filetype $file fas_env conf
					}
						
					#${final_filetype}::display fas_env $file
				}
			}
		}
		# and I save the session
		# I think that this is useless, if necessary, the session was written before
		if { [catch { fas_session::write_session } error_string] } {
			fas_display_error $error_string fas_env
		}
	}
}
#puts "####################Starting profiler output#####################"
#puts "[::profiler::print ]"

