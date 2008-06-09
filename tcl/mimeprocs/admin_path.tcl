# admin_path is an action
lappend filetype_list admin_path

namespace eval admin_path {
	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		set result fashtml
		# Now there may be other cases
		variable done
		set done 1
		fas_debug "admin_path::new_type -> $result "
		return $result
	}

	proc init { } {
		variable done
		set done 0
	}

	# List of possible types in which this file type may be converted
	proc new_type_list { } {
		return [list fashtml]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	# Return the list of environment variables that are important
	proc env { args } {
		set env_list ""
		lappend env_list [list "admin_path.template" "Html file with special tags for displaying a path depending of the directory structure." webmaster]
		return $env_list
	}

	# List of block that this filetype may send back
	proc block_list { } {
		return [list admin_path::admin_path]
	}
		

	proc content2fashtml { current_env content } {
		upvar $current_env fas_env
		return  ""
	}
	
	# Convert into html the input and return the corresponding
	# string.
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		# What is the real filename to take the content from ?
		set real_filename [fas_name_and_dir::get_real_filename path $filename fas_env]

		# Basically launching page_to_menu but in taking
		# all informations from the current_env variable
		set template_name [fas_name_and_dir::get_template_name fas_env admin_path.template]
		set root_dir [add_root ""]

		fas_debug "admin_path::2fashtml - root_dir -> $root_dir"

		# And on the template
		fas_depend::set_dependency $template_name file

		set content [page_to_admin_path $template_name $filename]
		return $content
	}

	# page_to_path
	# Create a "path" toto > titit > xxxx with links
	# Use a template for the look. - SECTION (normal link) ENDSECTION (last link)
	# blocks are used in the template.
	# template_name : the full file name of the template including the directory,
	# end : the last file or directory of the "path"
	# Example : root - /tmp/ucometest/any  (menu.name = Home)
	#           end - /tmp/ucometest/any/using/fr/use.txt ( Home > Use > French > Utilisation )
	# with links to the respective directories except for the last page
	proc page_to_admin_path { template_name end } {
		fas_debug "admin_path::page_to_path - $template_name - $end"
		set title ""
		# First getting the template file
		# Is there a cache file
		atemt::read_file_template_or_cache "$template_name" "$template_name"
		fas_debug_parray atemt::_atemt "admin_path::page_to_menu -> atemt::_atemt"
		# Now extracting the lol corresponding to the menu
		# expand_path remove any .. of a path
		set end [expand_path $end]
		fas_debug "admin_path::page_to_admin_path - end - $end"
		# Create a lol with ( file or dir name - menu name ) as elementary list
		# for each element in the path.
		set current_path_list [file split [rm_root $end]]
		generate_path_html $current_path_list
		#fas_debug "path::generate_path_html ----------------------------"
		#fas_debug "path::page_to_menu -> $atemt::_atemt(PATH)"
		# I think that I do not need the next line
		atemt::atemt_set $template_name -bl [atemt::atemt_subst -block PATH $template_name]
		set final_html [atemt::atemt_subst -end $template_name]
		return $final_html
	}
				  

	# From now I should be able to generate the graphics
	proc generate_path_html { path_list } {
		fas_debug "admin_path::generate_path_html - $path_list"
		# I suppose that I have an ordered list of elements
		# I just have to go through this ordered list and to add the elements
		# to the template.
		set path "/"
		if { [llength $path_list] > 1 } {
			fas_debug "admin_path::generate_path_html - dealing with [lrange $path_list 0 end-1]"
			foreach unit_path [lrange $path_list 0 end-1] {
				# With content = path, I can use directly the template of path
				set path [file join "$path" $unit_path] 
				set content $unit_path
				# I will have to test if this part is active or not		
				set atemt::_atemt(PATH_ENTRY) $atemt::_atemt(SECTION)
				set atemt::_atemt(PATH) [atemt::atemt_subst -insert -block PATH_ENTRY PATH]
			}
		}
		set path [lindex $path_list end]
		set content $path
		fas_debug "admin_path::generate_path_html - dealing with $path"
		# I will have to test if this part is active or not		
		set atemt::_atemt(PATH_ENTRY) $atemt::_atemt(ENDSECTION)
		set atemt::_atemt(PATH) [atemt::atemt_subst -insert -block PATH_ENTRY PATH]
		fas_debug "admin_path::generate_path_html - PATH -> $atemt::_atemt(PATH)"

	}
}
