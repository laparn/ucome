# FILE : fas_basic_proc.tcl
# Basic procedures
# $Id: fas_basic_proc.tcl,v 1.6 2002/07/03 15:24:54 arnaud Exp $
# vim: syntax=tcl:
#

# Here I create a standard string with standard procedures
# used in moste types
global ::STANDARD_PROCEDURES
set ::STANDARD_PROCEDURES {
	proc 2menu { current_env filename } {
		# In fact, I have nothing to do, because
		# the file is not important. I send back nothing
		return ""
	}
	proc 2mini_menu { current_env filename } {
		return ""
	}

	proc 2treedir { current_env filename } {
		return ""
	}

	proc 2title { current_env filename } {
		upvar $current_env fas_env
		fas_debug "[get_title $filename]"
		if { [info exists fas_env(title.title)] } {
			return "$fas_env(title.title)"
		} else {
			return "[get_title $filename]"
		}
	}

	proc 2copy_form { current_env filename } {
		return ""
	}
	
	proc 2copy { current_env filename } {
		return ""
	}

	proc 2edit_form { current_env filename } {
		return ""
	}
	
	proc 2edit { current_env filename } {
		return ""
	}
	proc 2delete_form { current_env filename } {
		return ""
	}
	
	proc 2delete { current_env filename } {
		return ""
	}

	proc 2prop_form { current_env filename } {
		return ""
	}

	proc 2show_prop { current_env filename } {
		return ""
	}
	
	proc 2prop { current_env filename } {
		return ""
	}
	
	proc 2clean_cache_form { current_env filename } {
		return ""
	}
		
	proc 2clean_cache { current_env filename } {
		return ""
	}

	proc 2select_file { current_env filename } {
		return ""
	}
	proc 2show_select_file { current_env filename } {
		return ""
	}

	proc 2txt4index { current_env filename } {
		return ""
	}

	proc 2txt4index_tree { current_env filename } {
		return ""
	}

	proc 2create_index { current_env filename } {
		return ""
	}

	proc 2search { current_env filename } {
		return ""
	}

	proc 2test_display_error { current_env filename } {
		return ""
	}

	proc 2env { current_env filename } {
		return ""
	}

	proc 2list_actions { current_env filename } {
		return ""
	}

	proc 2allow_action_form { current_env filename } {
		return ""
	}

	proc 2allow_action { current_env filename } {
		return ""
	}

	proc 2allow_action_final { current_env filename } {
		return ""
	}

	proc 2show_action_list { current_env filename } {
		return ""
	}
	proc 2login_form { current_env filename } {
		return ""
	}
	proc 2login { current_env filename } {
		return ""
	}
	proc 2whoami { current_env filename } {
		return ""
	}
	proc 2logout { current_env filename } {
		return ""
	}
	proc 2change_look { current_env filename } {
		return ""
	}
	proc 2path { current_env filename } {
		return ""
	}
	proc 2admin_path { current_env filename } {
		return ""
	}
	proc 2admin { current_env filename } {
		return ""
	}
	proc 2small { current_env filename } {
		return ""
	}
	proc 2nice_fax_name { current_env filename } {
		return ""
	}
	proc 2menu_form { current_env filename } {
		return ""
	}
	proc 2archive_full { current_env filename } {
		return ""
	}
	proc 2full_menu { current_env filename } {
		return ""
	}
	proc 2show_debug_file { current_env filename } {
		return ""
	}
	proc local_conf_list { } {
		variable local_conf
		return [array get local_conf]
	}
	proc 2ucome_doc { current_env filename } {
		return ""
	}
	proc 2search_form { current_env filename } {
		return ""
	}
	proc 2next { current_env filename } {
		return ""
	}
	proc ucome_doc { } {
		if { [catch { variable ucome_doc; return $ucome_doc } ] } {
			return ""
		}
	}
	proc 2mpeg21 { current_env filename } {
		return ""
	}
	proc 2candidate_order { current_env filename } {
		return ""
	}
	# begin modif Xav
	proc 2rrooll_param { current_env filename } {
		return ""
	}
	proc 2rrooll { current_env filename } {
		return ""
	}
	# end modif Xav
	proc 2xspf { current_env filename } {
		return ""
	}

	# Adding action test_session
	proc 2test_session { current_env filename } {
		return ""
	}
}

global ::INIT_ACTION
set ::INIT_ACTION {
	proc init { } {
		variable done
		set done 0
	}
	proc local_conf_list { } {
		variable local_conf
		return [array get local_conf]
	}
}

global ::STANDARD_ACTION_PROCEDURES

set ::STANDARD_ACTION_PROCEDURES {
	proc new_type { current_env filename } {
		# This is the default answer
		set result final
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list final ]
	}

	# Return the list of environment variables that are important
	# If this function is not defined, it is a final type that can
	# not be converted
	proc env { args } {
		set env_list ""
		return $env_list
	}
}
	
# The language variable is used everywhere to determine the current
# language
global LANGUAGE
set LANGUAGE ""

######################## Preparing the translation of the code
proc translate { sentence } {
	global ::_
	set language [international::language]
	if { [info exists "::${language}::_($sentence)"] } {
		#fas_debug "<font color=green>fas_debug_proc.tcl - translate - found translation</font>"
		return "[set "::${language}::_($sentence)"]"
	} else {
		#fas_debug "<font color=orange>fas_debug_proc.tcl - translate - ${language}::_($sentence) does not exist</font>"
		if { [info exists ::_($sentence)] } {
			return $::_($sentence)
		} else {
			return $sentence
		}
	}
}

namespace eval international {
	variable LANGUAGE
	set LANGUAGE ""

	proc init_language { language } {
		variable LANGUAGE
		set LANGUAGE $language
	}

	proc language { } {
		variable LANGUAGE
		return $LANGUAGE
	}
}

namespace eval fr {
	proc fax_date { year month day hour minute second } {
		return "${day}/${month}/${year} � ${hour}:${minute}:${second}"
	}
}

# Procedure for filetypes where there are no automatic conversion
# Then an "autocache" file may exists. It is xxxx.ext.html . I
# take it if necessary. If it does not exist I send back an error
# args should be either pdf or txt or html, html being the default
proc get_autocache_content { real_filename args } {
	set autocache_target_filetype html
	if { [llength $args] > 0 } {
		set autocache_target_filetype [lindex $args 0]
	}
	set autocache_file [get_autocache_filename $real_filename $autocache_target_filetype]
	# Even if it does not exist, if it comes to appear, it depends on it
	fas_depend::set_dependency $autocache_file
	fas_debug "fas_basic_proc::get_autocache_content - autocache_file => $autocache_file"
	if { [file readable ${autocache_file}] } {
		set content ""
		# OK I take it

		if { [catch {
			set fid [open ${autocache_file}]
			if { $autocache_target_filetype == "pdf" } {
				fconfigure $fid -encoding binary -translation binary
			}
			set content [read $fid]
			close $fid
		} ] } {
			set content "fas_basic_proc.tcl::get_autocache_content [translate "Problem while loading autocache file :"] $autocache_file"
		}
	} else {
		set content "fas_basic_proc.tcl::get_autocache_content [translate "No autocache file defined"] $autocache_file"
	}
	return $content
}

# args should be either html pdf or txt
# The name will be :
# file = /tmp/ucometest/any/test/test.sxw
# result = /tmp/ucometest/any/test/autocache/test.sxw.html
proc get_autocache_filename { filename args} {
	set extension html
	if { [llength $args] > 0 } {
		set extension [lindex $args 0]
	}
	# I add autocache to the directory name. I could
	# use a hidden directory, but I prefer to keep it
	# like that.
	# I am going to create a specific directory
	set autocache_dir [file join [file dirname $filename] autocache]
	
	return [file join $autocache_dir "[file tail ${filename}].${extension}"]
}

# This procedure will send back 1 if the variable 
# exists in _cgi_uservar, 0 otherwise
proc fas_cgi_exists { name } {
	global _cgi_uservar
	return [info exists _cgi_uservar($name)]
}

# This procedure will send the value back for a cgi variable
# or an error if it does not exist
proc fas_cgi_get { name } {
	global _cgi_uservar
	return $_cgi_uservar($name)
}

# This procedure may be used to set a given value
proc fas_cgi_set { name value } {
	global _cgi_uservar
	set _cgi_uservar($name) $value
}
		
# This procedure will search for a variable in fas_env, session and _cgi_uservar
# The priority is exactly in the other order
proc fas_get_value { name args } {
	fas_fastdebug {fas_basic_proc::fas_get_value name => $name args => $args}
	set state parse_args
	set DEFAULT_VALUE_FLAG 0
	set NO_ENV_FLAG 0
	set NO_SESSION_FLAG 0
	set NO_CGI_FLAG 0

	# NO_ENV_FLAG 0
	# if it is to 1 then, I will not search in fas_env for the name variable
	# -noe : not seached in fas_env
	# -nos : not searched in session
	# -noc : not searched in imported variables
	foreach arg $args {
		switch -exact -- $state {
			parse_args {
				switch -glob -- $arg {
					-d* {
						set state default
						set DEFAULT_VALUE_FLAG 1
					}
					-noe* {
						# noenv
						set NO_ENV_FLAG 1
					}
					-nos* {
						# nosession
						set NO_SESSION_FLAG 1
					}
					-noc* {
						# no cgi_uservar
						set NO_CGI_FLAG 1
					}
				}
			}
			default {
				set default_value $arg
				set state parse_args
			}
		}
	}

	global fas_env
	global fas_session::session
	global _cgi_uservar


	#fas_debug_parray _cgi_uservar "fas_basic_proc::fas_get_value => _cgi_uservar"
	set found_name 0
	set value ""

	if { !$NO_ENV_FLAG } {
		if [info exists fas_env($name)] {
			set found_name 1
			set value $fas_env($name)
		}
	}

	if { !$NO_SESSION_FLAG } {
		if [info exists fas_session::session($name)] {
			set found_name 1
			set value $fas_session::session($name)
		}
	}

	if { !$NO_CGI_FLAG } {
		if [info exists _cgi_uservar($name)] {
			set found_name 1
			set value $_cgi_uservar($name)
		}
	}

	if { $found_name } {
		return $value
	} else {
		if { $DEFAULT_VALUE_FLAG } {
			return $default_value
		} else {
			error 0 "get_value - Could not find $name"
		}
	}
}

#################### Import a variable
#
# Import a given variable shout in case of errors and add it to the error messages
# Always sendback a value, eventually empty. If they are errors the values must
# not be processed any longer.
# errors (which gives the nber of errors)
# errstr (which is the string of the errors) 
# MUST EXIST in the calling environment
#
# If an argument -mandatory is given, it means that the variable is mandatory
# then an error message is generated if its length is 0 or if it could not be imported 
#
# if the value _("$name") exists in the array _ then it is used in the error message
#
# Other possible option than mandatory are :
# -number
#	* if nothing is imported $default is used as a default value
#	* if a value is imported, it is cleaned up to be only numbers else an error is issued
# -percent
#	* as -number and any % sign is fully cancelled
# -year
# 	* a 2 or 4 digit number, if 2 => filled up to 4
# - month
#	* should be in the month list
# -password {{name} {firstname}}
#       * in this case the function ValidatePassword is called,
#	  it sends backs a list {1 "password"} or {0 "error message"} 
# -default value
# 	* if no value are imported for the variable then the default value is used
# Calling example :
# ImportVariable Name -mandatory
# ImportVariable Coefficient -number -default 1.0
# ImportVariable PartialTime -percent -default 100
# ImportVariable Flag -flag
	set _("Impossible\ to\ get\ ") "Impossible d obtenir"
	set _("\ -\ you\ did\ not\ call\ this\ script\ from\ the\ good\ place") " - vous n'avez pas appel� ce script de la bonne mani�re"
	set _("\ must\ be\ filled\ in\ -\ please\ go\ back\ and\ fill\ it\ !") " doit �tre rempli - merci de revenir en arri�re et de les remplir"
	set _("\ must\ be\ a\ number\ \(1.0\ or\ 1,5\)") " doit �tre un nombre (1.0 ou 1.5)"
	set _("Bad\ year\ specification") "Mauvaise sp�cification d'ann�e"
	set _("Not\ a\ valid\ month.") "Mois non valide"
	set _("Please\ try\ again.") "Merci d'essayer � nouveau"

proc ImportVariable { name args } {
	global _
	set result ""
	set default ""
	set mandatory 0
	set month 0
	set percent 0
	set number 0
	set flag 0
	set year 0
	set password 0
	set default_state 0
	set password_owner_list [list "" ""]

	set state flag
	
	foreach arg $args {
		switch -- $state {
			flag {
				switch -glob -- $arg {
					-ma* { set mandatory 1 }
					-nu* { set number 1 }
					-pe* { set number 1; set percent 1; }
					-fl* { set flag 1 }
					-ye* { set year 1 }
					-mo* { set month 1 }
					-de* { set state default; set default_state 1 }
					-pa* { set state password; set password 1; }
				}
			}
			default {
				set default $arg
				# come back to the flag examination
				set state flag
			}
			password {
				# password_owner is a list with name and firstname
				set password_owner_list $arg
				# come back to flag look
				set state flag
			}
		}
	}

	# From now I consider that the normal interface is not
	# cgi_import but the global variable _cgi_uservar
	#if { [catch { cgi_import_as $name result}] }
	global _cgi_uservar
	if { ![info exists _cgi_uservar($name)] } {
		if { $mandatory } {
			# There was a problem
			uplevel { incr errors }
			uplevel " append errstr \"$_(\"Impossible to get \")\" "
			if { [info exists _("$name")] } {
				set message $_("$name")
				uplevel "append errstr \"$message\""
			} else {
				uplevel "append errstr $name"
			}
			uplevel "append errstr \"$_(\" - you did not call this script from the good place\")\"; append errstr \"<br>\"; "
		}
		if { $flag } {
			# In this case, if no value was imported, it means that it is false
			set result 0
		}
		if { $default_state } {
			set result $default
		}
		if { $password } {
			set result ""
		}
	} else {
		set result $_cgi_uservar($name)
		# Now cleaning the input
		set result [string trim $result]
		if { $mandatory } {
			# it is a mandatory input and is empty, an error is generated
			if { [string length $result] < 1 } {
				uplevel { incr errors }
				if { [info exists _("$name")]  } {
					set message $_("$name")
				} else {
					set message $name
				}
				append message	$_(" must be filled in - please go back and fill it !"); append message "<br>"
				uplevel "append errstr \"$message\""
			}
		}
		if { $percent } {
			regsub -all "%" $result "" result
		}
		if { $number } {
			# Is it empty ?
			if { [string length $result] == 0 } {
				set result $default
			} else {
				# it must be a number with either . or , as separators
				# First, I substitute all , with a .
				regsub -all "," $result "." result
				# Next I verify that it is a number
				if { [regexp {[^- .01-9]} $result match] > 0 } {
					uplevel { incr errors }
					if { [info exists _("$name")] } {
						set message  $_("$name")
						uplevel "append errstr \"$message\""
					} else {
						 uplevel "append errstr $name";
					}
					uplevel {
						append errstr $_(" must be a number \(1.0 or 1,5\)")
						append errstr "<br>"
					}
				}
			}
		}
		if { $flag } {
			# a value comes, either it is 1 or not. If it is not, it is 0.
			if { $result != 1 } { set result 0}
		}
		if { $year } {
			# Now cleaning the year
			set result [string trim $result]
			# and verifying that it is valid (4 digits only - if 2 digits and < 99 then 2000 else 1999))
			if { [regexp {[0-9]+} $result match] <= 0} {
				if { $default_state } {
					set result $default
				} else {
					uplevel {
						incr errors
						append errstr $_("Bad year specification")
						append errstr "<br>"
					}
				}
			} elseif { [string length $result] == 2 } {
				# It is a 2 digit year then 00-99. If it is < 98 then it is 199?
				# else it is 20??
				if { $result < 98 } { set result "20$result" } else {
					set $result "19$result"
				}
			}
		# else it is a 4 digit year and I suppose that it is valid 
	    	}
		if { $month } {
			# just returns a number between 1 and 12
	    		# and verifying that it belongs to the MonthList
			if {[regexp {[^0-9]+} $result match] > 0 } { 
				uplevel {
					incr errors
					append errstr $_("Not a valid month.")
					append errstr "<br>"
				}
			} elseif { !(( $result > 0 ) && ( $result < 13 )) } {  
				uplevel {
					incr errors
					append errstr $_("Not a valid month.")
					append errstr "<br>"
				}
			}
		}
	}
	# If no password was given then I use "" as a default value, which is perfectly possible
	if { $password } {
		# I have a value for the password and I am supposed to have a default name list
		# I can now tryed to do the authentification
		set accepted_list [ValidatePassword $result $password_owner_list]
		set accepted [lindex $accepted_list 0]
		if { !$accepted } {
			uplevel {
				incr errors
			}
			uplevel "append errstr \"[lindex $accepted_list 1]\""
			uplevel {
				append errstr "<br>"
				append errstr $_("Please try again.")
				append errstr "<br>"
			}
		}
	}
	return $result;
}

#
# Universal way to get a cookie
#
proc fas_get_cookie { cookie_name } {
	global conf
	fas_debug "fas_basic_proc::fas_get_cookie - $cookie_name"

	if { [info exists conf(tclhttpd)] } {
		# I am in the tclhttpd case
		set result ""
		package require httpd::cookie
		set result [Cookie_Get $cookie_name]
		fas_debug "fas_get_cookie - tclhttpd - $cookie_name ->$result<-"
		if { $result == "" } {
			fas_debug "fas_basic_proc::fas_get_cookie - tclhttpd no cookie $cookie_name found"
			error 1
		} else {
			fas_debug "fas_basic_proc::fas_get_cookie - tclhttpd $cookie_name => $result"
			return $result
		}
	} elseif { [info exists conf(tclrivet) ] } {
		set value [cookie get $cookie_name]
		if { $value == "" } {
			fas_debug "fas_basic_proc::fas_get_cookie - rivet no cookie $cookie_name found"
			error "no cookie found"
		} 
		fas_debug "fas_basic_proc::fas_get_cookie - rivet cookie $cookie_name => $value"
		return $value
	} elseif { [info exists conf(websh) ] } {
		set value ""
		web::cookiecontext fas_context
		set value [fas_context::cget $cookie_name]
		#fas_context::commit
		if { $value == "" } {
			fas_debug "fas_basic_proc::fas_get_cookie - websh no cookie $cookie_name found"
			error "no cookie found"
		} 
		fas_debug "fas_basic_proc::fas_get_cookie - websh cookie $cookie_name => $value"
		return $value
	} else {
		# It is the cgi case
		#cgi_import_cookie $cookie_name
		set value [cgi_cookie_get -all $cookie_name]
		#return [set $cookie_name]
		fas_debug "fas_basic_proc::fas_get_cookie - cgi $cookie_name => $value"
		return $value
	}
}

#
# Universal way to set a cookie
#
proc fas_set_cookie { cookie_name cookie_value } {
	global conf
	#global FAS_VIEW_URL
	fas_debug "fas_basic_proc::fas_set_cookie - $cookie_name <= $cookie_value"
	if { [info exists conf(tclhttpd)] } {
		package require httpd::cookie
		Cookie_Set -name $cookie_name -value $cookie_value -path $::FAS_VIEW_URL
		#set line "${cookie_name}=${cookie_value} ;path=${FAS_VIEW_URL} ;"
		#set sock $conf(sock)
		#Httpd_SetCookie $sock $line
		#Cookie_Set name $cookie_name value $cookie_value
	} elseif { [info exists conf(tclrivet)] }  {
		global FAS_HOSTNAME
		fas_debug "fas_basic_proc::fas_set_cookie rivet cookie set $cookie_name $cookie_value -path $::FAS_VIEW_URL -host $FAS_HOSTNAME"
		cookie set $cookie_name $cookie_value -path $::FAS_VIEW_URL -host $FAS_HOSTNAME 
		#if { $conf(mod_rewrite) } {
		#	global FAS_VIEW_REWRITE_URL
		#	cookie set $cookie_name $cookie_value -path $FAS_VIEW_REWRITE_URL -host $FAS_HOSTNAME
		#}
	} elseif { [info exists conf(websh)] }  {
		global FAS_HOSTNAME
		#fas_debug "WEBSH - fas_set_cookie not yet implemented - TO BE DONE"
		web::cookiecontext fas_context
		fas_context::init $cookie_name
		fas_context::cset $cookie_name $cookie_value
		#fas_context::commit
	} else {
		set $cookie_name $cookie_value
		cgi_export_cookie $cookie_name path=$::FAS_VIEW_URL
	}
}

#
# Procedure used to validate a password.
# Here I do not need to do anything, then the password is always validated
# I just send back 1
#
proc ValidatePassword { password owner_list } {
	return [list 1 ""]
}

# Add the root to the start of a file
# I strictly remove / from filename. If I do not, $ROOT is ignored when 
# filename starts with /.
proc add_root { filename } {
	global ::ROOT
	return [file join ${::ROOT}  [string trim $filename /]]
}

proc add_root2 { filename } {
    global ::ROOT
    set regexp "^${::ROOT}/.*"
    if [ regexp $regexp $filename] {
	return $filename
    } else {
	return [file join ${::ROOT}  [string trim $filename /]]
    }
}

# Delete the root from the start of a file
proc rm_root { filename } {
	global ROOT
	global fas_env
	#fas_debug "fas_basic_proc.tcl - [info level 0] <- [info level -1] <- [info level -2]"
	if { ![regexp "^${ROOT}(.*)$" $filename match short_filename] } {
		# Generating errors for each time I have this problem generates
		# endless problem. I decide to send back "/" instead
		# fas_display_error "fas_basic_proc.tcl::rm_root - [translate "Error processing :"] $filename [translate "<br>It is not allowed to access file outside"] $ROOT" fas_env
		set short_filename "/"
	}
	# Beware added recently !!
	if { $short_filename == "" } {
		set short_filename "/"
	}
	return $short_filename

	## Test Xavier
	# regexp ?options? pattern string ?matched_string_range? ?matched_subString1? ?matched_subString2? ...
	# fas_debug "fas_basic_proc::rm_root - ^${::ROOT}(.*)$ on $filename"
	# if { [regexp "^${::ROOT}(.*)$" $filename string_range short_filename] } {
	#	return $short_filename
	# } else {
	# 	return "/"
	# }
}

# Delete a directory from the start of a file
proc rm_dir { filename dir } {
	#fas_debug "fas_basic_proc.tcl - [info level 0] <- [info level -1] <- [info level -2]"
	if { ![regexp "^${dir}(.*)$" $filename match short_filename] } {
		error "No $dir at start of $filename"
	}
	# Beware added recently !!
	if { $short_filename == "" } {
		set short_filename "/"
	}
	return $short_filename
}		 

proc rm_root2 {filename} {
    # simply
    return [rm_root [add_root2 $filename]]
}

proc get_root {  } {
	global ::ROOT
	return [string trimright $::ROOT /]
}

# Procedure to normalise a path. Normalise means
# to suppress any .. in the path so :
# /tmp/test/xxx/../yy/../zz becomes /tmp/test
# Important for the security
proc normalise { path } {
	set path_list [file split $path]
	# Now find .. or ... or ...
	set index [lsearch -regexp $path_list {^\.[\.]+$}]
	#puts "$index"
	while { $index > -1 } {
		# I found something
		if { $index == 0 } {
			# ???? .. at start, no sense, it is an error
			error 1
		}
		if { $index == 1 } {
			#puts "index is 1"
			if { [llength $path_list] > 2 } {
				set path_list [lrange $path_list 2 end]
			} else {
				return ""
			}
		} else {
			set start_path_end_index [expr $index - 2]
			set end_path_start_index [expr $index + 1]
			set tmp_path_list [lrange $path_list 0 $start_path_end_index]
			#puts "spei => $start_path_end_index -- epsi => $end_path_start_index"
			if { [llength $path_list] > $end_path_start_index } {
				set tmp_path_list [concat $tmp_path_list [lrange $path_list $end_path_start_index end]]
			}
			set path_list $tmp_path_list
		}
		#puts "current path_list => $path_list"
		set index [lsearch -regexp $path_list {^\.[\.]+$}]
		#puts "$index"
	}
	return [eval file join $path_list]
}

# Used to verify the security
proc check_root { filename } {
	global ::ROOT
	if { [regexp "^${::ROOT}(.*)$" $filename match short_filename] } {
		return 1
	}
	return 0
}

# That is to vorbid access to .mana files or directory from the ftp.
proc check_ftp_path { filename } {
	if { [regexp {/\.mana$} $filename match short_filename] } {
		return 0
	}
	if { [regexp {/\.mana/} $filename match short_filename] } {
		return 0
	}
	return 1
}

# Adding a basic procedure to clean a name for putting it in a link
proc clean_filename { filename } {
    regsub -all {%}  $filename "%25" filename
    regsub -all {&}  $filename "%26" filename
    regsub -all {\+} $filename "%2b" filename
    regsub -all { }  $filename "+"   filename
    regsub -all {=}  $filename "%3d" filename
    regsub -all {#}  $filename "%23" filename
    regsub -all {/}  $filename "%2f" filename  
    return $filename
}
# I need a conf variable to put the list of successive filetype
set conf(filetype_list) ""

