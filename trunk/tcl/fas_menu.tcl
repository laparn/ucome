# Creation of the menu
# I will create a list of elements corresponding to directories in
# the root directory. Each element will be :
# * directory,
# * name to use when representing the directory,
# * 1 or 0 to know if it is or not the current branch of the directory
# So I will have the first list with the different base directories,
# the second with the second level elements and so on and so forth.
# An element will be either a file or a directory.

# Args :
# root : the root of the directory
# end : the current directory under examination
proc directory_menu_lol { root end } {
	# First I need to know the content of the current directory
	set dir_list [glob -nocomplain -types {d f} -- [file join $root *]]
	fas_debug "fas_menu.tcl:directory_menu_lol: $dir_list"
	set result_list ""
	foreach dir $dir_list {
		# The pb is the following. If a directory
		# does not appear in the menu, and after you give
		# it a tmpl.name and tmpl.order, then it must
		# appear. Then it is dependency : if it changes
		# it may impact the visual
		fas_depend::set_dependency $dir env
		read_all_env $root $dir dir_env
		fas_debug "fas_menu.tcl:directory_menu_lol: ----------- $dir ------------"
		if [info exists dir_env(tmpl.name)] {
			# parray dir_env
			set name $dir_env(tmpl.name)
			# it is a file to use for the menu
			set order 1000000
			if [info exists dir_env(tmpl.order)] {
				set order $dir_env(tmpl.order)
			}
			# Does this directory or file matches exactly the start of current_end
			set IS_ROOT_AT_START 0
			set REST_OF_MENU ""
			if { [string first $dir $end] == 0 } {
				fas_debug "fas_menu.tcl:directory_menu_lol: Found $dir at start of $end"
				set IS_ROOT_AT_START 1 
				if { [file type $dir] == "directory" } {
					set REST_OF_MENU [directory_menu_lol $dir $end ]
				}
			} else {
				fas_debug "fas_menu.tcl:directory_menu_lol: Could not find $dir at start of $end"
			}
			lappend result_list [list $dir $name $order $IS_ROOT_AT_START $REST_OF_MENU]
		}
		if [info exists dir_env] {
			unset dir_env
		}
	}
	fas_debug "fas_menu.tcl:directory_menu_lol: result_list ==> $result_list"
	return $result_list
}

# create_menu
# So from a template, I will start from the menu section
# then I will take the section subsection and subsubsection elements
# as well as the activesection activesubsection and activesubssubsection
# Then I will try to create a real menu with these elements.

# First I need to order the incoming list
proc order_menu_lol { menu_lol } {
	# TO do that I need to go through the menu list
	# and search for the leaf. Then I come back from on step and I order the list
	# First ordering the current menu :
	set current_menu_lol [lsort -index 2 -integer $menu_lol]
	# fas_debug "order_menu_lol - current_menu_lol - $current_menu_lol" 
	set index 0	
	foreach menu_list $current_menu_lol {
		if { [lindex $menu_list end] != "" } {
			set menu_list [lreplace $menu_list end end [order_menu_lol [lindex $menu_list end]]]
			set current_menu_lol [lreplace $current_menu_lol $index $index $menu_list]
		}
		incr index
	}
	return $current_menu_lol
}

# From the name of the file, I extract the url
# For that I need to know the rooturl and root itself
proc url_from_name { dirname root rooturl } {
	# First I suppress from dirname the start
	if { [string first $root $dirname] == 0 } {
		# I suppress from the start of dirname
		set current_string [string trimleft [string range $dirname [string length $root] end] "/"]
	} else {
		set current_string $dirname
	}
	return "$rooturl/$current_string"
}

# From now I should be able to generate the graphics
proc generate_menu_html { menu_lol section_level root rooturl} {
	fas_debug "fas_menu.tcl::generate_menu_html - $menu_lol - $section_level - $root - $rooturl"
	# I suppose that I have an ordered list of elements
	# I just have to go through this ordered list and to add the elements
	# to the template.
	foreach menu_list $menu_lol {
		# is this part active or not ?
		if { $section_level == 0 } {		
			set section_type SECTION
		} elseif { $section_level == 1 } {
			set section_type SUBSECTION
		} else {
			set section_type SUBSUBSECTION
		}
		if { [lindex $menu_list 3] == 1 } {
			fas_debug "generate_menu_html - found ACTIVE $section_type"
			set section_type "ACTIVE$section_type"
		}
		# I will have to test if this part is active or not		
		set atemt::_atemt(MENU_ENTRY) $atemt::_atemt($section_type)
		set url [url_from_name [lindex $menu_list 0] $root $rooturl]  
		set content [lindex $menu_list 1]
		set atemt::_atemt(MENU) [atemt::atemt_subst -insert -block MENU_ENTRY MENU]
		if { [lindex $menu_list end] != "" } {
			set sub_menu_lol [lindex $menu_list end]
			generate_menu_html $sub_menu_lol [expr $section_level + 1] $root $rooturl
		}
	}
}
#
# template_name : the full file name of the template including the directory,
# root : the root of this local site,
# end : place where the information for creating the menu will be taken from
# rooturl : url of the root directory
# -f file : name of a file from which to take the html content and the title
# -c content : content to use and not a file
# -t title : title of the generated page
# contentname : name of the content (the file that will be the content of the
#               template
proc page_to_menu { template_name root end rooturl args } {
	fas_debug "fas_menu.tcl:page_to_menu: - $template_name - $root - $end - $rooturl"
	set CONTENT_TYPE ""
	set title ""
	set state parse_args
	foreach arg $args {
		switch -exact -- $state {
			parse_args {
				switch -glob -- $arg {
					-f* {
						#content filename
						set state filename
					}
					-c* {
						# a string with a content
						set state content
					}
					-t* {
						# a string with a title
						set state title
					}
				}
			}
			filename {
				set contentname $arg
				set CONTENT_TYPE file
				set state parse_args
			}
			content {
				set content $arg
				set CONTENT_TYPE string
				set state parse_args
			}
			title {
				set title $arg
				set state parse_args
			}
		}
	}
	# fas_debug "page_to_menu : CONTENT_TYPE = $CONTENT_TYPE "

	# First getting the template file
	# Is there a cache file
	atemt::read_file_template_or_cache "$template_name" "$template_name"
	#fas_debug "fas_menu.tcl - page_to_menu - reading template $template_name"
	#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu atemt::_atemt ->"
	# Now getting the content - in theory, end is ok - from a template file
	switch -exact -- $CONTENT_TYPE {
		file {
			if { [catch {set fid [open $contentname]
				set full_file [read $fid] } ] } {
					global fas_env
					fas_display_error "fas_menu:page_to_menu - [translate "problem opening"] $contentname" fas_env
					fas_exit
			}
			fas_debug "page_to_menu : found file - getting content of $contentname"
			set content [extract_body $full_file]
			#fas_debug "page_to_menu : content is $content"
			set title [extract_title $full_file]
			close $fid
		}
		string {
			# nothing to do
			set title [extract_title $content]
			set content [extract_body $content]
		}
		default {
			global fas_env
			fas_display_error "$CONTENT_TYPE : page_to_menu - [translate "Unknown content to display"]" fas_env
			# exit is done by fas_display_error
		}
	}
	atemt::atemt_set TITLE -bl [list [list html $title]]
	atemt::atemt_set CONTENT -bl [list [list html $content]]
	# Now extracting the lol corresponding to the menu
	set end [expand_path $end]
	fas_debug "page_to_menu - end - $end"
	set current_menu_lol [order_menu_lol [directory_menu_lol $root $end ]]
	fas_debug "page_to_menu - $current_menu_lol"
	#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu"
	generate_menu_html $current_menu_lol 0 $root $rooturl
	fas_debug "page_to_menu ----------------------------"
	#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu - before main subst"
	#fas_debug "atemt::_atemt(CONTENT) - $atemt::_atemt(CONTENT)\n"
	#fas_debug "atemt::_atemt(template_name) - $atemt::_atemt($template_name)\n"
	#set atemt::_atemt($template_name) [atemt::atemt_subst -block CONTENT $template_name]
	#fas_debug "atemt::_atemt(template_name) - $atemt::_atemt($template_name)\n"
	set atemt::_atemt($template_name) [atemt::atemt_subst -vn -block MENU -block BOTTOM  -block CONTENT -block TITLE $template_name]
	#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu --- before end subst"
	set final_html [atemt::atemt_subst -end $template_name]
	#fas_debug_parray atemt::_atemt "fas_menu.tcl - page_to_menu"
	#fas_debug "page_to_menu ####################################### END ############ => $final_html \n"
	return $final_html
}
			  
proc extract_body { content } {
	#fas_debug "fas_menu.tcl::extract_body - entering with $content"
	if { [regexp {< *[Bb][Oo][Dd][Yy][^>]*>(.+)< */[Bb][Oo][Dd][Yy]} $content match body] } {
		# fas_debug "fas_menu.tcl::extract_body - found a body in $content == extracting ===> $body <==="
		return $body
	} else {
		fas_debug "fas_menu.tcl::direct content output"
		return $content
	}
}

proc extract_title { content } {
	if { [regexp {< *[Tt][Ii][Tt][Ll][Ee][^>]*>([^>]+)< */[Tt][Ii][Tt][Ll][Ee]} $content match title] } {
		return $title
	} else {
		return ""
	}
}

proc expand_path { end } {
	if {[string index $end 0] != "/"} {
		return "[pwd]/$end"
	} else {
		return $end
	}
}

