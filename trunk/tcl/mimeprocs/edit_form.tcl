# no extensions for edit_form
lappend filetype_list "edit_form"

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval edit_form {
	# At the end of the edit I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		# This is the default answer
		set result comp
		# edit_form type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.

		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "comp" ) && ( $new_type_option == "notmpl" ) } {
			set result fashtml
		}
		variable done 
		set done 1
		fas_debug "edit_form::new_type -> $result - done -> $done"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list treedir fashtml tmpl ]
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

	proc 2treedir { current_env args } {
		fas_debug "edit_form::2treedir - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2treedir { current_env args } {
		fas_debug "edit_form::content2treedir - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
	}
	
	proc 2tmpl { current_env args } {
		fas_debug "edit_form::2tmpl - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2tmpl { current_env args } {
		fas_debug "edit_form::content2tmpl - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
	}
	
	
	proc 2comp { current_env args } {
		fas_debug "edit_form::2tmpl - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args ]]
		global _cgi_uservar
		if { [info exists _cgi_uservar(from)] } {
			if { $_cgi_uservar(from) == "view" } {
				set tmp(####) "comp/view.form"
			}
		}
		return "[array get tmp]"
	}
	
	proc content2comp { current_env args } {
		fas_debug "edit_form::content2tmpl - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}
	
	# This procedure will do nothing, just take what was sent to it
	# and send it. Everything must be done in each type 2edit_form
	# procedure
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		# Where do I take the content from.
		set real_filename [fas_name_and_dir::get_real_filename edit_form $filename fas_env]
		fas_depend::set_dependency $real_filename file
		fas_debug "edit_form::2fashtml - real_filename -> $real_filename"
	
		set content ""
		if { ![catch {set fid [open $real_filename] } errMsg] } {
			catch {
				set content [read $fid]
				close $fid
			}
		} else {
			set content "[translate "Problem while displaying the edit_form of"] [rm_root $filename]"
		}
		return $content
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to edit a content. It must be a file."]</b></center></body></html>"
	}
}
