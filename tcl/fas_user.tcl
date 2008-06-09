# All functions related to the authorization of actions
namespace eval fas_user {
	global ::DEBUG_PROCEDURES
	eval $::DEBUG_PROCEDURES
	set name ""

	proc init { } {
		variable name
		set name ""
	}


	# So from the user name, the user variables ?, and the current_env
	# I am going to try to allow or deny the actions
	# So there is either * (all actions) * all users
	# Or a list for the actions. So I will use allow.action 
	# else I deny the action .
	proc allowed_action { file action current_fas_env } {
		upvar $current_fas_env fas_env
		variable name

		fas_debug "fas_user::allowed_action entering   - $file - $action"
		fas_debug_parray fas_env "fas_user::allowed_action fas_env"
		if { [array name fas_env allow.${action}] != "" } {
			# Is there * there ?
			if { $fas_env(allow.${action}) == "*" } {
				# It is allowed for everybody
				return 1
			} else {
				# It is the list of allowed users
				if { [lsearch $fas_env(allow.${action}) $name] > -1 } {
					# OK in the list
					return 1
				}
			}
		}

		# There is also an allow.all_actions entry
		if { [array name fas_env allow.all_actions] != "" } {
			# Is there * there ?
			if { $fas_env(allow.all_actions) == "*" } {
				# It is allowed for everybody
				return 1
			} else {
				# It is the list of allowed users
				if { [lsearch $fas_env(allow.all_actions) $name] > -1 } {
					# OK in the list
					return 1
				}
			}
		}

		return 0

	}

	# Get the list of allowed users associated with an action
	# each args argument is another action. The returned list is unique
	proc get_allowed_user_for_action { current_fas_env action args } {
		upvar $current_fas_env fas_env

		set action_list [list $action]
		eval lappend action_list $args

		set allowed_user_list [list]
		foreach action $action_list {
			if { [info exists fas_env(allow.${action})] } {
				foreach user $fas_env(allow.$action) {
					lappend allowed_user_list $user
				}
			}
		}

		if { [llength $args] > 0 } {
			return [lsort -unique $allowed_user_list]
		} else  {
			return $allowed_user_list
		}
	}

	proc set_user_name { user } {
		variable name
		set name $user
	}

	proc find_user_name { } {
		global ::env
		variable name 
		# Either I am in an identified session through apache
		if { [array name ::env REMOTE_USER] != "" } {
			set name $::env(REMOTE_USER)
			fas_debug "user::who_am_i - found $name"
		} else {
			# Or it is precised in the session variable
			if { [fas_session::exists REMOTE_USER] } {
				# It exists
				set name [fas_session::setsession REMOTE_USER]
			}
		}
		return $name
	}

	# I get the name of the directory associated with a user
	proc get_general_user_dir { current_fas_env  } {
		upvar $current_fas_env fas_env

		if { [info exists fas_env(user_dir)] } {
			set user_dir "$fas_env(user_dir)"
		} else {
			set user_dir "[add_root [file join [fas_name_and_dir::get_root_dir] user]]"
		}

		return $user_dir
	}

	# I load the variables associated with a user
	proc load_user_var { user current_fas_env} {
		upvar $current_fas_env fas_env
		array set user_var ""
		# I consider that the user_var is the file uservar.env
		set user_file "[file join [add_root [get_user_dir $user fas_env]] uservar.env]"
		fas_debug "fas_user::get_user_var - user_filename is $user_file"
		catch { read_env $user_file user_var }
	}


	proc who_am_i { } {
		variable name
		return $name
	}

	# I get the list of users
	proc get_user_list { current_fas_env } {
		upvar $current_fas_env fas_env

		set general_user_dir [get_general_user_dir fas_env]
 
		# I consider that it is the list of directories in this directory
		# However, it could be made totally differently (database access, ldap, 
		# reading of apache htpasswd file, ...)
		set dir_user_list [glob -nocomplain -directory $general_user_dir -types "d" *]
		fas_debug "fas_user::get_user_list in $general_user_dir : dir_user_list is $dir_user_list"
		set user_list [list]
		foreach dir $dir_user_list {
			lappend user_list [file tail $dir]
		}
		fas_debug "fas_user::get_user_list : result is $user_list"
		return $user_list
	}

	proc check_password { current_fas_env name password } {
		upvar $current_fas_env fas_env
		# That is the place where you can change the way password
		# are checked. As a very first solution, I am going to
		# create a password.txt file in the user directory. It will
		# be in clear. I will forbid the reading of this directory
		# to every body.
		set general_user_dir [get_general_user_dir fas_env]
 
		# First does the user exists ?
		set OK 0
		set candidate_password_filename [file join $general_user_dir "[password::clean_name $name].password"]
		# name/password.txt obsolete version
		#set candidate_password_filename [file join $general_user_dir [file tail $name] password.txt]
		fas_debug "fas_user::check_password - candidate_password_filename : ${candidate_password_filename}"
		if { [file exists $candidate_password_filename ] } {
			# good start 
			fas_debug "fas_user::check_password - reading password file"
			#catch {
				read_env $candidate_password_filename temp_array
				# name/password.txt obsolete version
				# set password_fid [open $candidate_password_filename]
				# Warning I just take the first line of the file
				# set good_password [gets $password_fid]
				# close $password_fid
				set good_password $temp_array(password.content)
				if { [string equal [string toupper [::md5::md5 -hex $password]] [string toupper $good_password]] } {
					# fine
					set OK 1
					fas_debug "fas_user::check_password - $password [::md5::md5 -hex $password] match $good_password"
				} else {
					fas_debug "fas_user::check_password - $password [::md5::md5 -hex $password] does not match $good_password"
				}
			#}
		}
		return $OK
	}
}
