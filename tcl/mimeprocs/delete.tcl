# no extensions for delete
lappend filetype_list delete

# And now all procedures 
namespace eval delete {
	# When the copy is done, I set it to 1.
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result fashtml
		# copy type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list  fashtml]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	# If this function is not defined, no one are important
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	# Return the list of environment variables that are important
	proc env { args } {
		set env_list ""
		return $env_list
	}

	# Delete a file or a directory. If a directory
	# is deleted, we try to delete it recursively
	# The error messages are returned when required.
	# If everything is OK then it returns nothing
	proc intelligent_delete { filename } {
		global FAS_VIEW_CGI
		fas_debug "delete::intelligent_delete - trying to delete $filename"
		# I test if the file exists or not
		if { ![file exists $filename] } {
			set errMsg "[translate "Could not delete "] [rm_root $filename] [translate "as file does not exist"]"
			error $errMsg $errMsg
		} elseif { ![file writable $filename] } {
			set errMsg "[translate "Could not delete "] [rm_root $filename] [translate "as file is not writable."]"
			error $errMsg $errMsg
		} elseif { [file isdirectory $filename] } {
			set error 0
			set errMsg ""
			# It is a directory, I must delete all
			# files recursivel 
			set file_list [glob -nocomplain -types "f" -directory $filename * .*]
			foreach file $file_list {
				if { [catch { intelligent_delete $file } error_string] } {
					incr error
					append errMsg "$error_string"
				}
			}
			# I must add .mana, else it is not suppressed and
			# it is not possible to suppress a directory
			set dir_list [glob -nocomplain -types "d" -directory $filename * .mana]
			
			foreach dir $dir_list {
				if { [catch { intelligent_delete $dir } error_string] } {
					incr error
					append errMsg "\n$error_string"
				} 
			}
			if { $error > 0 } {
				error $errMsg $errMsg
			}
		}

		# It is a file or a directory I just try to delete it
		if { [catch {file delete $filename} errMsg] } {
			error $errMsg $errMsg
		} else {
			fas_debug "delete::intelligent_delete - succesfull deletion of $filename"
		}
		# Now suppressing the env file
		if { [file writable [env_filename $filename] ] } {
			if { [catch {file delete [env_filename $filename]} ] } {
				set message "[translate "Problem while deleting "]  [translate " environment variables of"] <A HREF=\"${FAS_VIEW_CGI}?file=[rm_root "$filename"]\">${filename}</A><br>${error}<br>"
				error $message $message
			} 
		} else {
			fas_debug "delete::intelligent_delete - succesfull deletion of env [rm_root [env_filename $filename]]"
		}
	}
	
	# This procedure will translate create the html text for a copy
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		set target_name [rm_root $filename]

		# I will always ask to do it again
		fas_depend::set_dependency 1 always
		# First, I will use treedir after, and I must prepare
		# the url to use when cliking on a directory.
		set treedir::local_conf(url_start) "?action=edit_form&file="

		set message  ""
		# First I must import the target name
		if { [catch {intelligent_delete $filename} error_string ] } {	
			set message "[translate "Problem while deleting "] <A HREF=\"${FAS_VIEW_CGI}?file=[rm_root "$filename"]\">[rm_root ${filename}]</A><br>${error_string}<br>"
		} else {
			set message "[translate "Succesful suppression of"] [rm_root ${filename}]."
		}
		# And now displaying the result
		
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		global DEBUG
		if $DEBUG {
			set _cgi_uservar(debug) "$DEBUG"
		}
		set _cgi_uservar(action) "edit_form"
		set dir [file dirname $filename]

		# I need to now the filetype of dir
		read_full_env $dir local_env
		set filetype [guess_filetype $dir conf local_env] 
		global conf
		display_file $filetype $dir fas_env conf
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[ translate "It is not possible to delete a content. It must be a filename."]</b></center></body></html>"
	}
}
