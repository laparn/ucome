lappend filetype_list rrooll

namespace eval rrooll {
        set done 0
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		fas_fastdebug {rrooll::new_type $filename}

		upvar $current_env fas_env
		# When a rrooll is met, in what filetype will it be by default
		# translated ?
		return ""
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	#proc new_type_list { } {
	#	return [list htmf]
	#}

	# Return the list of environment variables that are important
	# If this function is not defined, it is a final type that can
	# not be converted
	#proc env { args } {
	#	set env_list ""
	#	lappend env_list [list "rrooll.template" "Template used to rrooll." admin]
	#	return $env_list
	#}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	proc get_title { filename } {
		return "[binary::get_title $filename]"
	}

	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename rrooll
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename rrooll
	}

	proc 2fashtml { current_env filename filetype} {
		fas_debug "rrooll::2fashtml $filename $filetype"
		upvar $current_env fas_env

		# if a customized action is defined we use it to generate the result
		# but rrooll actions are forbidden to avoid infinite loops
		if { [info exists fas_env(rrooll.command)] } {

			fas_debug "rrooll::2fashtml - calling command : ${fas_env(rrooll.command)}"
			return "[eval ${fas_env(rrooll.command)}]"

		} else {
			fas_debug "rrooll::2fashtml - standard procedure"

			set real_filename [fas_name_and_dir::get_real_filename $filetype $filename fas_env]
			fas_depend::set_dependency $real_filename file

			# Getting the template directory
			if { ![info exists fas_env(templatedir)] } {
				fas_debug "rrooll::2fashtml - no key templatedir, defaulting to xecim"
				set fas_env(templatedir) "/template/xecim"
			}

			# Getting the template file
			# If possible, we use a customized template file
			if { [info exists fas_env(rrooll.template)] } {
				fas_debug "rrooll::2fashtml - using customized rrooll template ${fas_env(rrooll.template)}"
				set template_file ${fas_env(rrooll.template)}
			} else {
				fas_debug "rrooll::2fashtml - using default rrooll template"
				set template_file "rrooll.template"
			}
			# Load the template file
			if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env $template_file] } errStr] } {
				fas_display_error "rrooll::2fashtml - [translate "Problem getting template name"] $template_file<br>${errStr}" fas_env
			} else {
				fas_debug "rrooll::2fashtml - template file is $template_name"
			}

			# Getting the dependencies for the template file
			fas_depend::set_dependency $template_name file

			# load $template_name into RROOLL_TEMPLATE
			atemt::read_file_template_or_cache "RROOLL_TEMPLATE" "$template_name"
			fas_debug "rrooll::2fashtml - $template_name has been read with success"

			# think to substitute the RROOLL_PARAM section is present
			## how to do this ???
			## I tried this :
			# rrooll_param::2fashtml fas_env $filename
			## but it seems to interrupt the page generation...
			## I also tried this :
			#atemt::set_block RROOLL_PARAM "rrooll_param"
			## but it hasn't effect

			# the CONTENT section embeds the file ;)
			set file_url "[fashtml::to_right_url \"$filename\" {} \"\"][rm_root $filename]"
			atemt::set_html CONTENT "<embed src=$file_url>"

			# substitute the variables
			atemt::atemt_set RROOLL_TEMPLATE -bl [atemt::atemt_subst -block CONTENT -block RROOLL_PARAM RROOLL_TEMPLATE]
			# Here there is filename and dir to substitute
			set content [atemt::atemt_subst -end RROOLL_TEMPLATE]

			fas_debug "rrooll::2fashtml $filename $filetype - content is $content"

			# process fas: tags
			return "[fashtml::content2htmf fas_env $content \"\"]"
		}
	}

	proc display { current_env filename } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env fas_env
		fas_debug "rrooll::display - entering"

		# ??????????????? AL ?????????????
		# puts stdout "[2fashtml fas_env $filename rrooll]"
		return "[not_binary::content_display_with_session htmf [2fashtml fas_env $filename rrooll]]"
	}

	proc content { current_env filename } {
		upvar $current_env fas_env
		fas_debug "rrooll::content - entering"

		return "[2fashtml fas_env $filename rrooll]"
	}

}
