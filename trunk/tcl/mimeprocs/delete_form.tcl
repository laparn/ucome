# no extensions for delete_form
lappend filetype_list delete_form

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval delete_form {
	# At the end of the copy I set it at 1.
	# I will use it when changing of state
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION


	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		# This is the default answer
		set result comp
		# copy_form type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.

		variable done 
		set done 1
		fas_debug "delete_form::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list comp fashtml ]
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
		lappend env_list [list "delete_form.template" "Template used when preparing a file deletion." webmaster]
		return $env_list
	}

	proc 2comp { current_env args } {
		fas_debug "delete_form::2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval 2fashtml env $args]]
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "delete_form::content2comp - $args"
		upvar $current_env env
		array set tmp ""
		set tmp(content.content) [extract_body [eval content2fashtml env $args ]]
		return "[array get tmp]"
	}
	
	proc get_file_and_dir_list { dir } {
		set all ""

		set dir_list [glob -nocomplain -types d -directory $dir *]
		
		foreach current_dir $dir_list {
			lappend all $dir_list
			eval lappend all [get_file_and_dir_list $current_dir]
		}

		set file_list [glob -nocomplain -types f -directory $dir *]
		eval lappend all $file_list
		return $all
	}

	# html of all files and dir in a directory
	proc html_of_dir { dir } {
		# get the list of all files and directory
		set content "$dir<br>"
		foreach file [get_file_and_dir_list $dir] {
			append content "$file<br>"
		}
		return $content
	}

	# This procedure will translate create the html text for a copy
	proc 2fashtml { current_env filename } {
		fas_debug "delete_form::2fas_html - entering"
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		# First the dependencies :
		fas_depend::set_dependency $filename file

		# First, I will use treedir after, and I must prepare
		# the url to use when cliking on a directory.
		#set treedir::local_conf(url_start) "/cgi-bin/mana/fas_view.cgi?edit_dir=1&file="
		set treedir::local_conf(url_start) "?action=edit_form&file="

		# Getting the template
		set template_name [fas_name_and_dir::get_template_name fas_env delete_form.template]
		fas_depend::set_dependency $template_name file
		fas_debug "delete_form::2fas_html - template is $template_name"

		if { [catch { atemt::read_file_template_or_cache "DELETE_TEMPLATE" "$template_name" } ] } {
			fas_debug "delete_form::2fashtml - problem loading $template_name"
			#return "<div align=\"center\"><b>[translate "Problem while opening template"] $template_name</b></div>"
			fas_display_error "[translate "Problem while opening template"] $template_name" fas_env
		}

		# Is it a file or a directory
		if { [file isdirectory $filename] } {
			# Preparing the variables
			atemt::set_html FILENAME "[html_of_dir $filename]"
			
			atemt::set_html TITLE "[translate "Delete form for directory "] [rm_root $filename]"
			atemt::set_html FILETYPE "[translate "directories and files"]"
		} else {
			# Preparing the variables
			atemt::set_html FILENAME "[rm_root $filename]"
			
			atemt::set_html TITLE "[translate "Delete form for file"] [rm_root $filename]"
			atemt::set_html FILETYPE "[translate file]"
		}
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		set icons_url [fas_name_and_dir::get_icons_dir]
		set export_filename [rm_root $filename]
		regsub -all {%}  $export_filename "%25" export_filename
		regsub -all {&}  $export_filename "%26" export_filename 
		regsub -all {\+} $export_filename "%2b" export_filename
		regsub -all { }  $export_filename "+"   export_filename
		regsub -all {=}  $export_filename "%3d" export_filename
		regsub -all {#}  $export_filename "%23" export_filename
		regsub -all {/}  $export_filename "%2f" export_filename
		set dir [file dirname $export_filename]
		# No reason to do substitution here
		set atemt::_atemt(DELETE_TEMPLATE) [atemt::atemt_subst -block FORM -block TITLE -block FILENAME -block FILETYPE DELETE_TEMPLATE]
		# Here there is filename and dir to substitute
		fas_debug "delete_form::2fas_html - finishing"
		return [atemt::atemt_subst -end DELETE_TEMPLATE]
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		variable done
		set done 1
		return "<html><body><center><b>It is not possible to delete a content. It must be a filename.</b></center></body></html>"
	}
}
