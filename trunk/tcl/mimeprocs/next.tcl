# menu is an action. You may ask it on any file
# and it will send you back the menu corresponding
# to the current file. It needs no input.
# the file that was send before.
lappend filetype_list next

namespace eval next {
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
		# Now there may be other cases
		variable done
		set done 1
		fas_debug "menu::new_type -> $result "
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
		return $env_list
	}

	# List of block that this filetype may send back
	proc block_list { } {
		return [list next::next]
	}
		

	proc 2fashtml { current_env filename } {
		fas_debug "next::2fashtml - entering"
		upvar $current_env fas_env

		# Basically launching page_to_menu but in taking
		# all informations from the current_env variable
		global _cgi_uservar
		fas_debug_parray _cgi_uservar "next::2fashtml - _cgi_uservar. Is previous there ?"
		if { [info exists _cgi_uservar(previous)] } {
			set template_name [fas_name_and_dir::get_template_name fas_env previous.template]
		} else {	
			set template_name [fas_name_and_dir::get_template_name fas_env next.template]
		}
		# And on the template
		fas_depend::set_dependency $template_name file
		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env
		set root_menu_dir [add_root [fas_name_and_dir::get_menu_start_dir fas_env]]
		set content [page_to_next $template_name $root_menu_dir $filename] 
		return $content
	}

	proc page_to_next { template_name root filename } {
		fas_debug "next::page_to_next - $template_name - $root - $filename "
		set icons_url [fas_name_and_dir::get_icons_dir]
		set title ""
		# Reading the cache
		atemt::read_file_template_or_cache ALLNEXT "$template_name"
		# Now extracting the lol corresponding to the menu
		# expand_path remove any .. of a path
		set end [expand_path $filename]
		fas_debug "next::page_to_next - filename - $filename"
		set final_filename $filename
		if { [regexp {index\.} [file tail $filename] match] } {
			# this is a directory
			set final_filename [file dirname $filename]
		}
		set current_menu_lol [order_menu_lol [directory_menu_lol $root $final_filename ]]
		# I need to find the next (or previous) element
		global _cgi_uservar
		if { [info exists _cgi_uservar(previous)] } {
			set find_next [find_previous $current_menu_lol [list "" ""]]
		} else {
			set find_next [find_next $current_menu_lol 0]
		}
		fas_debug "next::page_to_next : find_next => $find_next"
		if { [lindex $find_next 0] == "2" } {
			set tmp_list [lindex $find_next end]
			fas_debug "next::page_to_next : tmp_list => $tmp_list"
			set url [lindex $tmp_list 0]
			set content [lindex $tmp_list 1]
			fas_debug "next::page_to_next : url => $url , content => $content"
			atemt::atemt_set ALLNEXT -bl [atemt::atemt_subst -block CONTENT ALLNEXT]
		} elseif { [lindex $find_next 0] == "1" } {
			if { ![info exists _cgi_uservar(previous)] } {
				# I am in the next case, but at the end of the list
				# then the next one, is the first one
				set menu_list [lindex $current_menu_lol 0]
				set url [rm_root [lindex $menu_list 0]]
				set content [lindex $menu_list 1]
				fas_debug "next::page_to_next : last case : url =>$url , content => $content"
				atemt::atemt_set ALLNEXT -bl [atemt::atemt_subst -block CONTENT ALLNEXT]
			} else {
				# I think that it can happen : it means it was the first page
				# and we must show the last one.
				# So I must find the last page.
				set menu_list [find_last $current_menu_lol]
				set url [lindex $menu_list 0]
				set content [lindex $menu_list 1]
				fas_debug "next::page_to_next : previous find_last, first page, mode url => $url , content => $content"
				atemt::atemt_set ALLNEXT -bl [atemt::atemt_subst -block CONTENT ALLNEXT]
			}
		} else {
			# I need a fall-back mode, if nothing is found.
			# First fall back would be first and last of the list
			# Second fall back would be the same but at the level in the tree
			# where I am.
			# I am going to run find_next or find_previous in looking for
			# not exact but for only start, and going as far as possible ?
			#set find_next [find_next $current_menu_lol 0 -fallback]
			#fas_debug "next::page_to_next : fall_back find_next => $find_next"
			#if { [lindex $find_next 0] == "2" } {
			#	set tmp_list [lindex $find_next end]
			#	fas_debug "next::page_to_next : fall_back tmp_list => $tmp_list"
			#	set url [lindex $tmp_list 0]
			#	set content [lindex $tmp_list 1]
			#	fas_fastdebug {next::page_to_next : url => $url , content => $content}
			#	atemt::atemt_set ALLNEXT -bl [atemt::atemt_subst -block CONTENT ALLNEXT]
			#} else {
				# I have found nothing, I use fallback
				# first and last element of the lol
				# first element
				if { ![info exists _cgi_uservar(previous)] } {
					set menu_list [lindex $current_menu_lol 0]
					set url [rm_root [lindex $menu_list 0]]
					set content [lindex $menu_list 1]
					fas_fastdebug {next::page_to_next : second fall_back mode url => $url , content => $content}
					atemt::atemt_set ALLNEXT -bl [atemt::atemt_subst -block CONTENT ALLNEXT]
				} else {
					set menu_list [find_last $current_menu_lol]
					set url [lindex $menu_list 0]
					set content [lindex $menu_list 1]
					fas_debug "next::page_to_next : previous find_last, first page, mode url => $url , content => $content"
					atemt::atemt_set ALLNEXT -bl [atemt::atemt_subst -block CONTENT ALLNEXT]
				}
					
			#}

		}
		set final_html [atemt::atemt_subst -end ALLNEXT]
		return $final_html
	}
				  
	# First I need to order the incoming list
	proc order_menu_lol { menu_lol } {
		fas_debug "next::order_menu_lol - entering"
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

	# Creation of the menu
	# I will create a list of elements corresponding to directories in
	# the root directory. Each element will be :
	# * directory,
	# * name to use when representing the directory,

	# Args :
	# root : the root of the directory
	# end : the current directory under examination
	# -auto : use the tail name of the file as the name
	#       : if tmpl.name does not exist
	proc directory_menu_lol { root end args } {
		fas_debug "next::directory_menu_lol : entering - $root $end $args"
		# AUTO_MENU_FLAG defines if I try to create or not
		# automatically the menu name
		set AUTO_MENU_FLAG 0
		set CALLING_AUTO_MENU_FLAG 0
		if { [llength $args] > 0 } {
			set AUTO_MENU_FLAG 1
			# If the procedure is call in menu.auto mode
			# then I need to use and propagate it.
			# However, if I find a directory which is in menu.auto
			# I must not pollute the next directories at the same level
			# with it. That's why I introduce CALLING_AUTO_MENU_FLAG
			set CALLING_AUTO_MENU_FLAG 1
		}
		# I must put a dependency on the directory
		#fas_depend::set_dependency $root file
		# And on the .mana directory
		#fas_depend::set_dependency [file join $root .mana] file

		# First I need to know the content of the current directory
		# Directory and file
		set dir_list [glob -nocomplain -types {d f} -- [file join $root *]]
		fas_debug "next::directory_menu_lol - root -> $root, end -> $end"
		fas_debug "next::directory_menu_lol - $dir_list"
		set result_list ""
		foreach dir $dir_list {
			# The pb is the following. If a directory
			# does not appear in the menu, and after you give
			# it a tmpl.name and tmpl.order, then it must
			# appear. Then it is dependency : if it changes
			# it may impact the visual
			#fas_depend::set_dependency $dir env
			read_all_env $root $dir dir_env
			if { [info exists dir_env(menu.auto)] } {
				set AUTO_MENU_FLAG 1
			}
			fas_debug "menu::----------- $dir ------------"
			if { [info exists dir_env(menu.name)] || $AUTO_MENU_FLAG } {
				# parray dir_env
				if { [info exists dir_env(menu.name)] } {
					set name $dir_env(menu.name)
				} else {
					set name [file tail $dir]
				}
				# it is a file to use for the menu
				set order 1000000
				if [info exists dir_env(menu.order)] {
					set order $dir_env(menu.order)
				}
				# Does this directory or file matches exactly the start of current_end
				set IS_ROOT_AT_START 0
				set REST_OF_MENU ""
				if { [string first $dir $end] == 0 } {
					#fas_debug "next::directory_menu_lol - Found $dir at start of $end"
					if { [string match $dir $end] } {
						set IS_ROOT_AT_START 2
						fas_fastdebug {next::directory_menu_lol : found exact match ${dir} - ${end}}
					} elseif { [string first "${dir}/index." $end] == 0 } {
						# I suppose that if dir is a directory, and the current file
						# is index.xxx then, it is the file displayed when the directory
						# is asked. It is not perfect, as in some rare case index. may
						# not be what is displayed (and there may be many index. files).
						fas_fastdebug {next::directory_menu_lol : special case for exact match ${dir}/index. is at start of ${end}}
						set IS_ROOT_AT_START 2
					} else {
						fas_fastdebug {next::directory_menu_lol : ${dir} at start of ${end}}
						set IS_ROOT_AT_START 1 
					}
					if { [file type $dir] == "directory" } {
						if { $AUTO_MENU_FLAG } {
							set REST_OF_MENU [directory_menu_lol $dir $end -auto ]
						} else {
							set REST_OF_MENU [directory_menu_lol $dir $end ]
						}
					}
				} else {
					fas_debug "next::directory_menu_lol - Could not find $dir at start of $end"
				}
				lappend result_list [list $dir $name $order $IS_ROOT_AT_START $REST_OF_MENU]
			}
			if [info exists dir_env] {
				unset dir_env
			}
			set AUTO_MENU_FLAG $CALLING_AUTO_MENU_FLAG
		}
		fas_debug "next::directory_menu_lol - result_list ==> $result_list"
		return $result_list
	}

	# From now I should be able to find the next one
	proc find_next { menu_lol FOUND_FLAG args} {
		fas_fastdebug {next::find_next - $menu_lol $FOUND_FLAG}
		# ?????????????????????????? => pb in directories
		#set FOUND_FLAG 0
		# If there was not an exact match found, I fall back on a 
		# nearly as good solution
		set FALL_BACK_MODE 0
		if { [llength $args] > 0 } {
			set FALL_BACK_MODE 1
		}
		fas_fastdebug {next::find_next FOUND_FLAG => $FOUND_FLAG}
		foreach menu_list $menu_lol {
			if $FOUND_FLAG {
				set current_filename [rm_root [lindex $menu_list 0]]
				set content [lindex $menu_list 1]
				fas_fastdebug {next::find_next - found $current_filename - $content}
				return [list "2" [list "$current_filename" "$content"]]
			} else {
				if !$FALL_BACK_MODE {
					# Normal mode
					if { [lindex $menu_list 3] == "2" } {
						# The current menu_list is an exact match
						set FOUND_FLAG 1
						fas_fastdebug {next::find_next - found exact match - I am on : $menu_list}
					}
				} else {
					# We are in fallback mode, if I am just on the entry, I use it
					if { [lindex $menu_list 3] == "1" } {
						set FOUND_FLAG 1
						fas_fastdebug {next::find_next - fall_back_mode found exact match - I am on : $menu_list}
					}
				}
			}
			if { [lindex $menu_list end] != "" } {
				# I enter in a recursive mode 
				set sub_menu_lol [lindex $menu_list end]
				if !$FALL_BACK_MODE {
					set result_next [find_next $sub_menu_lol $FOUND_FLAG]
				} else {
					set result_next [find_next $sub_menu_lol $FOUND_FLAG $args]
				}
				if { [lindex $result_next 0] == "2" } {
					fas_fastdebug {next::find_next - recursively found $result_next}
					return $result_next
				}
				if { [lindex $result_next 0] == "1" } {
					if !$FALL_BACK_MODE {
						set FOUND_FLAG 1
						fas_fastdebug {next::find_next - recursively found exact match : $result_next}
					} else {
						# In fallback I use it directly.
						# Maybe, I should wait.
						lset result_next 0 2
						return $result_next
					}
				}
			}
		}
		fas_fastdebug {next::find_next - found nothing}
		return "[list $FOUND_FLAG [list]]"
	}

	# From now I should be able to find the previous one
	proc find_previous { menu_lol previous_result } {
		fas_fastdebug {next::find_previous - $menu_lol $previous_result}
		foreach menu_list $menu_lol {
			set current_filename [rm_root [lindex $menu_list 0]]
			set content [lindex $menu_list 1]
			if { [lindex $menu_list 3] == "2" } {
				return [list 2 $previous_result]
			}
			if { [lindex $menu_list end] != "" } {
				set sub_menu_lol [lindex $menu_list end]
				set result_previous [find_previous $sub_menu_lol [list $current_filename $content]]
				if { [lindex $result_previous 0] == "2" } {
					fas_debug "next::find_previous - recursively found $result_previous"
					return $result_previous
				}
				set previous_result [lindex $result_previous 1]
			} else {
				set previous_result [list $current_filename $content]
			}
		}
		return "[list 0 $previous_result]"
	}

	# From now I should be able to find the last one
	proc find_last { menu_lol } {
		fas_fastdebug {next::find_last - $menu_lol}
		set menu_list [lindex $menu_lol end]
		if { [lindex $menu_list end] != "" } {
			set result [find_last [lindex $menu_list end]]
		} else {
			set current_filename [rm_root [lindex $menu_list 0]]
			set content [lindex $menu_list 1]
			set result [list $current_filename $content]
		}
		return $result
	}
}
