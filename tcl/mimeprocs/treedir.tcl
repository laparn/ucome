lappend filetype_list treedir

namespace eval treedir {
	set local_conf(url_start) "?action=edit_form&file="

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set done 0

	proc new_type { current_env filename } {
		# When a tmpl is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) htmf
		# This is the default answer
		set result fashtml
		# Action is done
		variable done
		set done 1
		# Now there may be other cases
		
		return $result
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
		lappend env_list [list "treedir.template" "Html file with special tags for creating a hierarchical view of the directory structure." webmaster]
		return $env_list
	}

	proc block_list { } {
		return [list treedir::treedir]
	}

	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		return  [generic2fashtml fas_env $filename ]
	}
	
	proc content2fashtml { current_env content } {
		upvar $current_env fas_env
		# I use root_directory as the filename
		set filename [fas_name_and_dir::get_root_dir]
		#if { [info exists fas_env(root_directory)] } {
		#	set filename "$fas_env(root_directory)"
		#} else { 
		#	fas_display_error "[translate "No key"] root_directory [translate "was defined in the current file environment variables. Please define it."]" fas_env
		#}
		return  [generic2fashtml fas_env $filename ]
	}
	
	# Convert into html the input and return the corresponding
	# string.
	# -nocache : do not try to take or to write a cachefile
	# filename : file from which to take the content

	# There are 2 different cases : in copy_form treedir
	# is used to choose the directory of the target file. Then
	# filename (2html current_env filename) is not the
	# filename that will be used for displaying treedir. 
	# In other words, the displayed treedir has nothing to
	# do with the final treedir. The name is taken from
	# the imported variable dir.
	# The other problem is the link used when clicking on a
	# directory of treedir. It must give one action or another
	# and is configurable. Basically what is used is :
	# ${FAS_VIEW_URL}$local_conf(url_start)$env(root_directory)
	# + the name of the directory that is clicked on.
	proc generic2fashtml { current_env filename args} {
		upvar $current_env env
		set NOCACHE 0
		set CONTENT_TYPE ""
		set content_string ""
		set state parse_args
		foreach arg $args {
			switch -exact -- $state {
				parse_args {
					switch -glob -- $arg {
						-n* {
							#nocache
							set NOCACHE 1
						}
					}
				}
			}
		}

		# What is the real filename to take the content from ?
		# In copy_form, I use treedir to choose the target directory
		if { [fas_get_value action_from -default "view"] == "copy_form" } {
			# I am going to use the dir key as the real
			# value for the directory. filename is the
			# name of the file to copy. If dir does not
			# exists I use it as the real filename
			set real_filename [fas_name_and_dir::get_real_filename treedir $filename env]
			set filename [add_root [fas_get_value dir -default "[rm_root $filename]"]]
		} else {
			set real_filename [fas_name_and_dir::get_real_filename treedir $filename env]
		}

		# Basically launching page_to_menu but in taking
		# all informations from the current_env variable

		set template_name [fas_name_and_dir::get_template_name env "treedir.template"]
		fas_depend::set_dependency $template_name file
		variable local_conf
		fas_debug "treedir::generic2fashtml - local_conf(url_start) -> $local_conf(url_start)"
		global _cgi_uservar
		if { [info exists _cgi_uservar(treedir.url_start)] } {
			fas_debug "treedir::generic2fashtml - taking treedir.url_start from _cgi_uservar"
			set local_conf(url_start) $_cgi_uservar(treedir.url_start)
		}
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env
			
		global FAS_VIEW_URL
		set content [page_to_dir $template_name [fas_name_and_dir::get_root_dir] $filename "${FAS_VIEW_URL}$local_conf(url_start)[fas_name_and_dir::get_root_dir]"]
		return $content
	}

	#
	# template_name : the full file name of the template including the directory,
	# root : the root of this local site,
	# end : place where the information for creating the menu will be taken from
	# rooturl : url of the root directory
	# Beware here the file is a directory, not a real file ?
	proc page_to_dir { template_name root end rooturl } {
		fas_debug "page_to_dir : entering template -> $template_name , root -> $root , end -> $end , rooturl -> $rooturl "
		set CONTENT_TYPE ""
		set title ""
		set state parse_args
		# First getting the template file
		# Is there a cache file
		atemt::read_file_template_or_cache "TREEDIR_TEMPLATE" "$template_name"
		fas_debug "form::2fashtml TREEDIR_TEMPLATE => [atemt::atemt_set TREEDIR_TEMPLATE]"
		# Now getting the content - in theory, end is ok - from a template file

		# Now extracting the lol corresponding to the menu
		set end [expand_path $end]
		fas_debug "treedir::page_to_dir - end - $end"
		# Here I add the root to the directories that are displayed
		if { [string match [string trim $root "/"]  [string trim $end "/"] ] } {
			set IS_ROOT_AT_START 2
		} else {
			set IS_ROOT_AT_START 1
		}
		#set current_menu_lol [order_directory_lol [list [list "[add_root $root]" "/" $IS_ROOT_AT_START [directory_lol [add_root $root] $end ]]]]
		set current_menu_lol [order_directory_lol [list [list "[add_root $root]" "$root" $IS_ROOT_AT_START [directory_lol [add_root $root] $end ]]]]
		# in current_menu_lol all filenames are exact (all path components 
		# including the root at start
		generate_dirtree_html $current_menu_lol 0 $root $rooturl
		# Just for the cache
		set export_filename [rm_root $end]
		fas_debug "form::2fashtml DIRTREE => [atemt::atemt_set DIRTREE]"
		fas_debug "form::2fashtml TREEDIR_TEMPLATE => [atemt::atemt_set TREEDIR_TEMPLATE]"
		atemt::atemt_set TREEDIR_TEMPLATE -bl [atemt::atemt_subst -block CACHE TREEDIR_TEMPLATE]
		#set atemt:_atemt($template_name) [atemt::atemt_subst -block CACHE $template_name]
		fas_debug "form::2fashtml TREEDIR_TEMPLATE => [atemt::atemt_set TREEDIR_TEMPLATE]"
		#Used in Ecim template
		set current_action "edit_form"
		#atemt::atemt_set TREEDIR_TEMPLATE -bl [atemt::atemt_subst -vn -block DIRTREE TREEDIR_TEMPLATE]
		# -vn is a bad option for Ecim. Why was it there before ?
		global FAS_VIEW_CGI
		set icons_url [fas_name_and_dir::get_icons_dir]
		atemt::atemt_set TREEDIR_TEMPLATE -bl [atemt::atemt_subst -block DIRTREE TREEDIR_TEMPLATE]
		fas_debug "form::2fashtml TREEDIR_TEMPLATE => [atemt::atemt_set TREEDIR_TEMPLATE]"
		#set atemt::_atemt($template_name) [atemt::atemt_subst -vn -block DIRTREE $template_name]
		#set final_html [atemt::atemt_subst -end TREEDIR_TEMPLATE]
		set final_html [atemt::atemt_subst_end TREEDIR_TEMPLATE]
		fas_debug "treedir::page_to_dir ####################################### END ############ => $final_html"
		return $final_html
	}
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
	# I am going to simplify this code. I just display the directory name
	# and in an alphabetical order.
	proc directory_lol { root end } {
		# First I need to know the content of the current directory
		set dir_list [glob -nocomplain -types {d} -- [file join $root *]]
		fas_debug "treedir::directory_lol - $dir_list"
		set result_list ""
		foreach dir $dir_list {
			#read_all_env $root $dir dir_env
			fas_debug "----------- $dir ------------"
			set name [file tail $dir]
			#if [info exists dir_env(name)] {
			#	set name $dir_env(name)
			#}
			#set order 1000000
			#if [info exists dir_env(treedir.order)] {
			#	set order $dir_env(order)
			#}
			# Does this directory or file matches exactly the start of current_end
			set IS_ROOT_AT_START 0
			set REST_OF_MENU ""
			if { [string first $dir $end] == 0 } {
				fas_debug "treedir::directory_lol - Found $dir at start of $end"
				if { [string match $dir $end] } {
					set IS_ROOT_AT_START 2
				} else {
					set IS_ROOT_AT_START 1 
				}
				set REST_OF_MENU [directory_lol $dir $end ]
			} else {
				fas_debug "directory_lol - Could not find $dir at start of $end"
			}
			fas_depend::set_dependency $dir file
			lappend result_list [list $dir $name $IS_ROOT_AT_START $REST_OF_MENU]
			#if [info exists dir_env] {
			#	unset dir_env
			#}
		}
		fas_debug "treedir::directory_lol - result_list ==> $result_list"
		return $result_list
	}

	# create_menu
	# So from a template, I will start from the menu section
	# then I will take the section subsection and subsubsection elements
	# as well as the activesection activesubsection and activesubssubsection
	# Then I will try to create a real menu with these elements.

	# First I need to order the incoming list
	proc order_directory_lol { menu_lol } {
		# To do that I need to go through the menu list
		# and search for the leaf. Then I come back from on step and I order the list
		# First ordering the current menu :
		set current_menu_lol [lsort -index 0 $menu_lol]
		# fas_debug "order_menu_lol - current_menu_lol - $current_menu_lol" 
		set index 0	
		foreach menu_list $current_menu_lol {
			if { [lindex $menu_list end] != "" } {
				set menu_list [lreplace $menu_list end end [order_directory_lol [lindex $menu_list end]]]
				set current_menu_lol [lreplace $current_menu_lol $index $index $menu_list]
			}
			incr index
		}
		return $current_menu_lol
	}

	# From the name of the file, I extract the url
	# For that I need to know the rooturl and root itself
	proc url_from_name { dirname root rooturl } {
		fas_debug "treedir::url_from_name, dirname - $dirname , root - $root , rooturl - $rooturl"
		set dirname [rm_root $dirname]
		# First I suppress from dirname the start
		if { [string first $root $dirname] == 0 } {
			# I suppress from the start of dirname
			set current_string [string trimleft [string range $dirname [string length $root] end] "/"]
		} else {
			set current_string $dirname
		}
		#fas_debug "treedir::url_from_name - current_string : $current_string"
		return "$rooturl/${current_string}"
	}


	# From now I should be able to generate the graphics
	# So here I generate the tree.
	proc generate_dirtree_html { dir_lol section_level root rooturl} {
		fas_debug "treedir::generate_dirtree_html,"
		fas_debug "	 dir_lol - $dir_lol ,"
		fas_debug "	 section_level - $section_level ,"
		fas_debug " 	 root - $root ,"
		fas_debug "	 rooturl - $rooturl"
		set icons_url [fas_name_and_dir::get_icons_dir]
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		# I suppose that I have an ordered list of elements
		# I just have to go through this ordered list and to add the elements
		# to the template.
		# In fact there will be very few different sections,
		# you will only have to show different directory type if
		# it is or not active and to put an amount of space before
		# the display
		foreach menu_list $dir_lol {
			set section_type "DIR"
			set space_type "SPACE"
			if { [lindex $menu_list 2] == 2 } {
				fas_debug "treedir::generate_dirtree_html - found EXACT $section_level"
				set section_type "EXACTDIR"
				set space_type "EXACTSPACE"
			}
			if { [lindex $menu_list 2] == 1 } {
				fas_debug "treedir::generate_dirtree_html - found ACTIVE $section_level"
				set section_type "ACTIVEDIR"
				set space_type "ACTIVESPACE"
			}
			# I will have to test if this part is active or not		
			set atemt::_atemt(CURRENTDIR) $atemt::_atemt($section_type)
			# Now I add all the necessary spaces in CURRENTDIR
			for { set counter 0 } { $counter < $section_level } { incr counter } {
				set atemt::_atemt(CURRENTDIR) [atemt::atemt_subst -vn -insert -block $space_type CURRENTDIR]
			}
			set url [url_from_name [lindex $menu_list 0] $root $rooturl] 
			set export_filename [rm_root [lindex $menu_list 0]]
			#set icons_url [fas_get_value icons_url -default "fas:/icons"]	
			set content [lindex $menu_list 1]
			#set atemt::_atemt(DIRTREE) [atemt::atemt_subst -insert -block CURRENTDIR DIRTREE]
			atemt::atemt_set DIRTREE -bl [atemt::atemt_subst_insert CURRENTDIR DIRTREE]
			fas_debug "generate_dirtree_html : DIRTREE => $atemt::_atemt(DIRTREE)"
			if { [lindex $menu_list end] != "" } {
				set sub_menu_lol [lindex $menu_list end]
				generate_dirtree_html $sub_menu_lol [expr $section_level + 1] $root $rooturl
			}
		}
		fas_debug "form::generate_dirtree_html - end : DIRTREE => $atemt::_atemt(DIRTREE)"
	}
	proc extract_body { content } {
		if { [regexp {< *[Bb][Oo][Dd][Yy][^>]*>(.+)< */[Bb][Oo][Dd][Yy]} $content match body] } {
			return $body
		} else {
			return $content
		}
	}

	proc extract_title { content } {
		if { [regexp {< *[Tt][Ii][Tt][Ll][Ee][^>]*>([~<]+)< */[Tt][Ii][Tt][Ll][Ee]} $content match title] } {
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

	proc content_display { current_env content } {
		upvar $current_env env
		htmf::content_display env $content
	}
	
	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env env
		global DEBUG
		
		
		# it is a file
		if { [catch {open $filename} fid] } {
			fas_display_error "treedir::display - could not open $filename" -file $filename
		} else {
			set content [read $fid]
			close $fid
			cgi_eval {
				# BEWARE TO BE IMPROVED
				# It would be better with a template
				cgi_html {
					cgi_body "bgcolor=#ffffff" {
						cgi_preformatted {
							cgi_puts "$content"
						}
						if { $DEBUG } {
							global DEBUG_STRING
							cgi_hr
							cgi_p "[cgi_b "DEBUG"]"
							cgi_preformatted "$DEBUG_STRING"
						}	
					}
				}
			}
		}
	}

}
