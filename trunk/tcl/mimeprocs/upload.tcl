# no extensions for copy
lappend filetype_list upload

# Procedures for uploading a file to the server
namespace eval upload {
	# When the copy is done, I set it to 1.
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
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
		return [list dir ]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	# If this function is not defined, no one are important
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	# Return the list of environment variables that are important
	# If this function is not defined, it is a final type that can
	# not be converted
	proc env { args } {
		set env_list ""
		return $env_list
	}

	
	# This procedure will create the html text for an upload 
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		fas_depend::set_dependency 1 always

		fas_debug "upload::2fashtml - entering"
		set message  "Result of upload"
		global conf
		if { [info exists conf(tclrivet)] } {
			# rivet case
			set client_name [upload filename uploaded_file]
			set target_name [file join $filename [file tail $client_name]]
			upload save uploaded_file $target_name
			set message "upload - [translate "Succesful upload of"] [rm_root $target_name]"
		} else {
			# First I must import the target name
			if { [catch { set server_name [cgi_import_file -server uploaded_file]
				      set client_name [cgi_import_file -client uploaded_file]
			} error ] } {
				set message "upload.tcl - [translate "No file on the server. Problem while uploading."]<br>$error"
			} else {
				# The target filename is the end of the file on the client
				# in the current directory	
				set target_name [file join $filename [file tail $client_name]]
				fas_debug "upload::2fashtml - target_name -> rm_root $target_name"
				if { [catch {file copy $server_name $target_name} error] } {
					set message "upload - [translate "Problem while uploading "] [rm_root $target_name]<br>"
				} else {
					set message "upload - [translate "Succesful upload of"] [rm_root $target_name]"
				}
				catch { file delete $server_name }
			}
		}
		# And now displaying the result
		# No reason to do substitution here
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
		global conf
		display_file dir $filename fas_env conf
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to upload a content. It must be a file."]</b></center></body></html>"
	}
}
# The UploadDone of tclhttpd is not good for me
# as httpdReturnData is called in it. I handle that after.
# Then I rewrite this function.
proc UploadDone {sock} {
}

