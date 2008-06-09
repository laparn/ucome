namespace eval fas_name_and_dir {

	# Procedures defined here are :
	# get_real_filename - from a filename and a type, checked the name
	#                     for the cache file or the original file
	# get_template_name_from_comp - from a composite file get the template name
	# get_comp_name : name of a composite file, used to display
	#                 a file.
	# get_comp_dir : name of the directory where composite files are stored
	# get_template_name : get a template name for a template description (view, edit_form, ...)
	# get_template_dir : directory where templates are stored
	# get_icons_dir : url of a directory name
	# get_root_dir : get the root_directory from which everything is organised
	# get_session_dir : the directory where session files are stored

	global ::DEBUG_PROCEDURES
	eval $::DEBUG_PROCEDURES

# I wonder if this procedure is useful. Basically, the filename
# to display is right. I see no reason to check it.
	proc get_real_filename { filetype filename current_env } {
		fas_fastdebug {fas_name_and_dir::get_real_filename $filetype $filename}
		# Trying to get the realname from the file to display.
		# I search for a cached file in the cache directory
		# corresponding to $filetype. If there is nothing
		# there I then send back the filename if it exists
		# else I throw an error
		#fas_debug "Entering get_real_filename"
		upvar $current_env env
		# So I first look in the cache directory
		set FOUND_FILE 0
		set final_filename "$filename"
		set cache_filename "[cache_filename $filetype $filename env]"
		#fas_debug "fas_name_and_dir::get_real_file_name - potention cache_filename : $cache_filename"
		# The pb is the following : if you go twice through a filetype
		# it takes a previous cached file. So I do the following thing :
		# if conf(filetype_list) is equal to 1, then I take the original
		# file, else I take the file cached.
		# This leads to an error with comp files, when I edit them the
		# first time, it takes the original comp, and after that it takes
		# the cached comp.
		if { [file readable $cache_filename] } {
			set FOUND_FILE 1
			set final_filename $cache_filename
		} ; # no cache file

		if { !$FOUND_FILE } {
			if { ![file readable $final_filename] } {
				fas_display_error "fas_name_and_dir::get_real_file_name - Could not open [rm_root2 $final_filename]" env
			} ; # else nothing to do, the name is the good one
		} else {
			# I must know if it is nevetherless final_filename
			global ::conf
			fas_fastdebug {fas_name_and_dir::get_real_filename : special case with a file found -> conf(filetype_list) -> $conf(filetype_list)}
			if { [llength $conf(filetype_list)] > 1 } {
				# it is cache_filename
				set final_filename $cache_filename
			} else {
				set final_filename $filename
			}
		}
		fas_fastdebug {fas_name_and_dir::get_real_filename - found $final_filename}
		return $final_filename
	}


	# In fact, here I get the name of the template related to
	# a composite file.
	# Basically, I find them in the template directory ?
	# or I create a dedicated directory ?
	proc get_template_name_from_comp { current_env current_comp } {
		fas_fastdebug {fas_name_and_dir::get_template_name_from_comp}
		upvar $current_comp comp
		upvar $current_env fas_env

		if { [info exists comp(global.template)] } {
			set comp_template_name $comp(global.template)
		} else {
			error "fas_name_and_dir::get_template_name_from_comp - [translate "No template define for current composite file"]"
		}
		set template_name [get_template_name fas_env $comp_template_name]
		return $template_name
	}
		
	# Allows to get the name of a comp file used to display
	# a file. It will be stored in fas_env(compdir) or fas_env(root_directory)
	# Basically, it should be stored
	# in fas_env(${action_name}.comp), else I take
	# ${file_type}.${action_name}.comp

	# The root does not need to be set here.
	proc get_comp_name { current_env filename {known_filetype comp}} {
		fas_fastdebug {fas_name_and_dir::get_comp_name current_env ${filename} <-- Entering}
		upvar $current_env fas_env

		# I take mimeproc from the action and the file
		global conf
		set filetype [guess_filetype $filename conf fas_env]

		global _cgi_uservar
		if { [info exists _cgi_uservar(action)] } {
			set action $_cgi_uservar(action)
		} else {
			set action view
		}
		# First what is the directory ?
		set comp_dir [get_comp_dir fas_env $known_filetype]

		# The directory is in comp_dir
		# Now what is the key
		if { [info exists fas_env(${filetype}.${action}.comp) ] } {
			fas_fastdebug {fas_name_and_dir::get_comp_name fas_env(${filetype}.${action}.comp) case}
			set comp_name $fas_env(${filetype}.${action}.comp)
		} else {
			# by default, I replace template by tmpl
			# WARNING - .form is suspect, should be .comp ?
			fas_fastdebug {fas_name_and_dir::get_comp_name ${filetype}.${action}.comp case}
			set comp_name ${filetype}.${action}.form
		}
		fas_fastdebug {fas_name_and_dir::get_comp_name may use  $comp_name}
		if { [info exists fas_env(${action}.comp) ] } {
			fas_fastdebug {fas_name_and_dir::get_comp_name  fas_env(${action}.comp) case}
			set simple_comp_name $fas_env(${action}.comp)
		} else {
			fas_fastdebug {fas_name_and_dir::get_comp_name may use  ${action}.form case}
			set simple_comp_name ${action}.form
		}
		fas_fastdebug {fas_name_and_dir::get_comp_name may use  $simple_comp_name}


		# Trying to introduce internationalisation of the template
		#set final_comp_name [file join $comp_dir [international::language] $comp_name]
		#set final_simple_comp_name [file join $comp_dir [international::language] $simple_comp_name]
		#if { ![file readable [add_root $final_comp_name]] } {
			#if { ![file readable [add_root $final_simple_comp_name]] } {
			#	if { ![file readable  [add_root [file join $comp_dir $comp_name]]] } {
			#		set final_comp_name [file join $comp_dir $simple_comp_name]
			#	} else {
			#		set final_comp_name [file join $comp_dir $comp_name]
			#	}
			#} else {
			#	set final_comp_name $final_simple_comp_name

			#}
		#}
		set real_comp_name [file join $comp_dir $comp_name]
		if { [file readable [add_root $real_comp_name]] } {
			# OK
		} else {
			set real_comp_name [file join $comp_dir $simple_comp_name]
			if { [file readable  [add_root  $real_comp_name]] } {
				# OK
			} else {
				set real_comp_name [file join $comp_dir "${known_filetype}.form"]
				if { [file readable  [add_root  $real_comp_name]] } {
					# OK
				} else {
					fas_display_error "Could not find any form. Tryed $comp_name , $simple_comp_name and ${known_filetype}.form in <b>$comp_dir</b>. No one found." fas_env
				}
			}
		}
		fas_fastdebug {fas_name_and_dir::get_comp_name will use  $real_comp_name}
		return $real_comp_name
	}

	# Directory where composite files are stored
	proc get_comp_dir { current_env {filetype comp}} {
		fas_fastdebug {fas_name_and_dir::get_comp_dir filetype->\'${filetype}\'}
		upvar $current_env fas_env
		set comp_dir ""

		if { $filetype == "comp" } {
			# First what is the directory ?
			if { [info exists fas_env(compdir) ] } {
				set comp_dir $fas_env(compdir)
				# Modified on 15/06/2004. Seems useless
				#if { [info exists fas_env(root_directory) ] } {
				#	set comp_dir "$fas_env(root_directory)/$comp_dir"
				#}
				set comp_dir "$fas_env(root_directory)/$comp_dir"
			} else {
				# Modified on 15/06/2004. Seems useless
				# if { [info exists fas_env(root_directory) ] } {}
				# 	set comp_dir "$fas_env(root_directory)/comp"
				if { [catch {set comp_dir "$fas_env(root_directory)/comp" }] } {
				#if { [catch {set comp_dir [add_root "/comp"]}] } 

					fas_display_error "fas_name_and_dir::get_comp_dir - [translate "No key"] compdir or root_directory [translate "was defined in the current file environment variables. Please define one of them."]" fas_env
				}
			}
		} else {
			# It is a todo or password, but not directly
			# a comp. I use the "domp" directory
			# First what is the directory ?
			if { [info exists fas_env(dompdir) ] } {
				set comp_dir [add_root $fas_env(dompdir)]
			} else {
				if { [catch {set comp_dir  "$fas_env(root_directory)/domp"}] } {

					fas_display_error "fas_name_and_dir::get_domp_dir - [translate "No key"] dompdir or root_directory [translate "was defined in the current file environment variables. Please define one of them."]" fas_env
				}
			}
		}

		fas_fastdebug {fas_name_and_dir::get_comp_dir $filetype returned $comp_dir}
		return $comp_dir
	}

	# Allows to get the name of a template, that is stored in
	# $fas_env(templatedir). Basically, it should be stored
	# in fas_env($template_env_key), else I take
	# $template_env_key.tmpl
	# Preparing change to .template
	# $template_env_key.template
	# In order to minimize the dupplication between directory
	# I am going to create a "standard" template directory
	# where standards will be stored.
	proc get_template_name { current_env template_env_key } {
		upvar $current_env fas_env
		if { [catch {set template_dir [get_template_dir fas_env]} msg] } {

			fas_display_error "get_template_name - $msg (please have a look at debug logs)" fas_env
			fas_debug "get_template_name - environment variables are :"
			fas_debug_parray fas_env ""

			#fas_display_error "get_template_name - [translate "No key"] templatedir, root_directory  [translate "was defined in the current file environment variables. Please define one of them."]" fas_env
		}
		fas_fastdebug {fas_name_and_dir::get_template_name - template_dir -> $template_dir}
		set final_template_env_key $template_env_key
		# Preparing change to .template
		# regsub {template} $template_env_key {tmpl} final_template_env_key
		# regsub {template} $template_env_key {tmpl} final_template_env_key
		set template_name [fas_get_value $template_env_key -default $final_template_env_key]
		#if { [info exists fas_env($template_env_key) ] } {
		#	set template_name $fas_env($template_env_key)
		#} else {
		#	# by default, I replace template by tmpl
		#	regsub {template} $template_env_key {tmpl} template_env_key
		#	set template_name $template_env_key
		#	
		#}

		# Trying to introduce internationalisation of the template
		set final_template_name [file join $template_dir [international::language] $template_name]
		fas_fastdebug {fas_name_and_dir::get_template_name - international::language [international::language]}
		fas_fastdebug {fas_name_and_dir::get_template_name - final_template_name -> $final_template_name}
		if { [file readable $final_template_name] } {
			fas_fastdebug {fas_name_and_dir::get_template_name - international::language [international::language]}
			fas_fastdebug {fas_name_and_dir::get_template_name - final_template_name -> $final_template_name}
			return $final_template_name
		}
		# There is no international template
		# Is there a local one ?
		set final_template_name [file join $template_dir $template_name]
		fas_fastdebug {fas_name_and_dir::get_template_name - final_template_name -> $final_template_name}
		if { [file readable $final_template_name] } {
			fas_fastdebug {fas_name_and_dir::get_template_name - final_template_name -> $final_template_name}
			return $final_template_name
		}

		# No local one, I turn toward the standard one
		fas_fastdebug {fas_name_and_dir::get_template_name - getting standard_template_dir}
		set standard_template_dir [get_standard_template_dir fas_env]
		fas_fastdebug {fas_name_and_dir::get_template_name - standard_template_dir - $standard_template_dir}
		set final_template_name [file join $standard_template_dir [international::language] $template_name]
		fas_fastdebug {fas_name_and_dir::get_template_name - international::language [international::language]}
		fas_fastdebug {fas_name_and_dir::get_template_name - final_template_name -> $final_template_name}
		if { [file readable $final_template_name] } {
			fas_fastdebug {fas_name_and_dir::get_template_name - international::language [international::language]}
			fas_fastdebug {fas_name_and_dir::get_template_name - final_template_name -> $final_template_name}
			return $final_template_name
		}
		# There is no international template
		# That's the last fall back
		fas_fastdebug {fas_name_and_dir::get_template_name - final_template_name -> $final_template_name}
		set final_template_name [file join $standard_template_dir $template_name]
		return $final_template_name
	}
	proc get_template_dir { current_env } {
		upvar $current_env fas_env
		if { [info exists fas_env(templatedir) ] } {
			set template_dir [add_root $fas_env(templatedir)]
		} elseif { [info exists fas_env(root_directory) ] } {
			
			set template_dir [file join [add_root $fas_env(root_directory)] template standard]
		} else {
			error "get_template_dir - could not determine template directory"
			fas_debug "get_template_dir - environment variables are :"
			fas_debug_parray fas_env ""
		}
		return $template_dir
	}
	proc get_standard_template_dir { current_env } {
		upvar $current_env fas_env
		if { [info exists fas_env(root_directory) ] } {
			set standard_template_dir [file join [add_root $fas_env(root_directory)] template standard]
		} else {
			error "get_template_dir - could not determine standard template directory"
		}
		return $standard_template_dir
	}

	# Directory where icons are stored for the internal working of ucome
	proc get_icons_dir {  } {
		set icons_url [fas_get_value icons_url -default "fas:[file join [get_root_dir] icons]"]
		return $icons_url

	}

	# Directory on which everything is based (cache, session, ...)
	proc get_root_dir { } {
		set root_directory [fas_get_value root_directory -default ""]
		return $root_directory
	}

	proc get_menu_start_dir { current_env } {
		upvar $current_env fas_env
		if { ![info exists fas_env(menu.menuroot) ] } {
			set menu_tail "any"
		} else {
			set menu_tail [string trim $fas_env(menu.menuroot) /]
		}
		return [file join [get_root_dir] $menu_tail]
	}
	proc get_mini_menu_start_dir { current_env } {
		upvar $current_env fas_env
		if { ![info exists fas_env(mini_menu.root) ] } {
			return [::fas_name_and_dir::get_menu_start_dir fas_env]
		} else {
			set menu_tail [string trim $fas_env(mini_menu.root) /]
			return [file join [get_root_dir] $menu_tail]
		}
	}
	proc get_full_menu_start_dir { current_env } {
		upvar $current_env fas_env
		if { ![info exists fas_env(full_menu.menuroot) ] } {
			if { ![info exists fas_env(menu.menuroot) ] } {
				set menu_tail "any"
			} else {
				set menu_tail [string trim $fas_env(menu.menuroot) /]
			}
		} else {
			set menu_tail [string trim $fas_env(full_menu.menuroot) /]
		}
		return [add_root $menu_tail]
	}

	proc get_txt4index_tree_start_dir { current_env } {
		upvar $current_env fas_env

		if { ![info exists fas_env(txt4index_tree.start)] } {
			set result  [get_menu_start_dir fas_env]
		} else {
			set result fas_env(txt4index_tree.start)
		}
		return $result
	}

	# Directory to store the session
	proc get_session_dir { } {
		set session_dir [fas_get_value session_dir -noc -nos -default [file join [get_root_dir] session]]
		return $session_dir
	}

	proc get_cache_dir { current_fas_env } {
		upvar $current_fas_env fas_env
		if { [info exists fas_env(cache)] } {
			set cache_dir "[file join $fas_env(cache)]"
			fas_fastdebug {fas_name_and_dir::get_cache_dir - using fas_env(cache) and $filetype => $cache_dir}
		} else {
			set cache_dir "[file join [fas_name_and_dir::get_root_dir] cache ]"
		}
		fas_fastdebug {fas_name_and_dir::get_cache_dir -> $cache_dir}
		return $cache_dir
	}
	# Is from defined ? Used to choose where to arrive after an
	# action was done. Most of the time edit_form or view.
	proc get_from { } {
		global ::_cgi_uservar
		set from view
		if { [info exists _cgi_uservar(from)] } {
			set from $_cgi_uservar(from)
		}
		return $from
	}
}

namespace eval any {
	# All environment variables that are common to all filetypes
	proc env { } {
		set env_list ""
		# The 2 next properties are deprecated by comp and menu action use
		#lappend env_list [list "tmpl.name" "Name displayed in menus" user]
		#lappend env_list [list "tmpl.order" "Display order in menus" user]
		lappend env_list [list "cache" "Directory in which files are cached" admin]
		lappend env_list [list "root_directory" "Base directory of the site." admin]
		lappend env_list [list "templatedir" "Directory where all templates are stored" admin]
		lappend env_list [list "session_dir" "Directory where session files are stored" admin]
		lappend env_list [list "icons_url" "Url when icons for administrative interface are stored" admin]
		lappend env_list [list "language" "Language" user]
		lappend env_list [list "file_index_dir"  "File used when the display of the directory is asked for." user]
		lappend env_list [list "file_type" "File type used for displaying the file." user]
		lappend env_list [list "dir_type" "File type used for displaying a directory." webmaster]
		return $env_list
	}

	# This procedure will import a list of values,
	# if the corresponding checkbox was checked
	# (used in allow_action and allow_action_final)
	# In the values imported, there should be
	# ${varname}0 ${varname}1 ${varname}2 ...
	# and the associated checkbox0 checkbox1 checkbox2
	# A value is put in the final list if its checkbox
	# was checked.
	proc import_checkbox_list { varname } {
		global ::_cgi_uservar
		set counter 0
		set result_list [list]
		while { [info exists _cgi_uservar(${varname}${counter})] } {
			set current_result $_cgi_uservar(${varname}${counter})
			if { [info exists _cgi_uservar(checkbox${counter})] } {
				if { $_cgi_uservar(checkbox${counter}) } {
					lappend result_list $current_result
				}
			}
			incr counter
		}
		return $result_list
	}
}	  
