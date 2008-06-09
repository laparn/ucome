# All functions for flattening an existing site
# I will start from the root directory, and
# create a lololol... with list of files and directories

# Then I will need a function for going threw this list 
# and applying one function or the other.

# A function will be to do a http query on each file having
# a name or being used and the second will be 
# to put all files and figures in a common tree

# I must also change the file name to show that
# they are html files and not txt, or tmpl. The link
# and images must also be updated.
# A link is updated if it starts with http://fsdf/../fas_view.cgi?file=
# the whole think including the root is replaced
# by a given string.

# In simplifying, the flatten operation is just :
#  * regroup html and gif files in the same arborescence
#  * change the name of html files from .xxx into .html
#  * change the link and img using the fas_view.cgi
#    in static links

# no extensions for flatten
lappend filetype_list "flatten"

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval flatten {
	# At the end of flatten I set it at 1.
	# I will use it when changing of state
	set done 0
	set level 0

	global DEBUG_PROCEDURES  INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set errors 0
	set errstr ""

	set not_graphic_list [list txt tmpl html fashtml htmf comp todo tcl code sxw sxc sxi csv xml]

	proc get_not_graphic_list { } {
		variable not_graphic_list
		return $not_graphic_list
	}

	proc new_type { current_env filename } {
		# At the end of flatten, we will display edit_form
		# on the root_directory 
		set result edit_form
		# flatten type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.
		variable done 
		set done 1
		fas_debug "flatten::new_type -> $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list edit_form]
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
		lappend env_list [list "flatten.target_url" "Base url of the target site." admin]
		lappend env_list [list "flatten.ignore" "Flag indicating that a site must be ignored (1 then)" user]
		lappend env_list [list "flatten.target_dir" "Directory where the flattened site is written" admin]
		return $env_list
	}

	proc 2edit_form { current_env args } {
		fas_debug "flatten::2edit_form - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2edit_form { current_env args } {
		fas_debug "flatten::content2edit_form - $args"
		upvar $current_env env
		return "[eval content2edit_form env $args ]"
	}
	
	# 
	# Let us do the flattening
	#
	proc 2fashtml { current_env filename } {
		fas_debug "flatten::2fashtml -------- STARTING FOR FILE $filename --------------"
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		# Always do again and again
		fas_depend::set_dependency 1 always

		# First, from where do I flatten ?
		set root_directory [add_root [fas_name_and_dir::get_root_dir] ]
		if { ![info exists fas_env(menu.menuroot) ] } {
			set fas_env(menu.menuroot) any
		}
		set root_menu_dir [file join $root_directory [string trim $fas_env(menu.menuroot) /]]


		# Then, what is the cache target directory ?
		if { [info exists fas_env(flatten.target_dir)] } {
			set target_dir [add_root $fas_env(flatten.target_dir)]
		} else {
			set target_dir [cache_filename flatten $root_directory fas_env -no_extension]
		}
		fas_debug "flatten::2fashtml - target_dir : $target_dir"

		# The root_url is obvious
		#????set root_url [fas_name_and_dir::get_root_dir]
		set root_url [file join [fas_name_and_dir::get_root_dir] $fas_env(menu.menuroot)]

		# Now what is the target url ?
		if { [info exists fas_env(flatten.target_url)] } {
			set target_url $fas_env(flatten.target_url)
		} else {
			set target_url "/flatten"
		}

		# OK now in theory, I can start the process
		# in using the existing routines

		# First, I try to create the cache directory
		if { [catch {file mkdir $target_dir} ] } {
			fas_display_error "flatten::2fashtml - [translate "Could not create directory"] $target_dir [translate "for storing flattened site."]" fas_env
			fas_exit
		}
		
		variable errstr	
		variable errors
		# Now copying all binary files
		global _cgi_uservar
		unset _cgi_uservar(action)	
		#process_dir fas_env $root_directory $target_dir "" $target_url
		process_dir fas_env $root_menu_dir $target_dir "" $target_url

		# Now taking the file of the cache and copying them
		# process_cache_dir $root_url $target_dir $target_url ""	

				
		return "$errstr"
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to edit a content. It must be a file."]</b></center></body></html>"
	}

	proc copy_graph { current_env root_dir target_dir relative_dir target_url } {
		upvar $current_env fas_env
		global conf
		variable errors
		variable errstr
		set final_target_dir [file join $target_dir $relative_dir]
		set ori_dir [file join $root_dir $relative_dir]

		variable not_graphic_list 
		fas_debug "flatten::copy_graph : $ori_dir"
		set file_list [glob -nocomplain -types {f} -- [file join $ori_dir *]]
		fas_debug "flatten::copy_graph found - $file_list"
		foreach file $file_list {
			read_full_env $file current_file_env
			set file_type [guess_filetype $file conf current_file_env ]
			if { ![info exists current_file_env(flatten.ignore)] &&  $file_type != "dir" } {
				fas_debug "flatten::copy_graph - filetype of $file is $file_type"
				if { [lsearch $not_graphic_list $file_type] == -1 } {
					# it is a graphic file, I copy it
					fas_debug "flatten::copy_graph : copying $file $final_target_dir"
					if { [ catch { file mkdir $final_target_dir } current_error ] } {
						incr errors
						append errstr "flatten::copy_graph - [ translate "Problem while copying "] [translate "to"] [rm_root $final_target_dir]<br>$current_error<br>"
					}
					if { [ catch { file copy -force $file $final_target_dir } current_error ] } {
						incr errors
						append errstr "flatten::copy_graph - [ translate "Problem while copying "] [rm_root $file] [translate "to"] [rm_root $final_target_dir]<br>$current_error"
					}
				} else {
					# it is not a graphic file, then I display it
					# get the content in html, and change all links
					set menu::done 0
					set treedir::done 0
					set content [display_file $file_type $file current_file_env conf -nod]
					fas_debug "flatten::copy_graph -------------content----------"
					fas_debug "$content"
					fas_debug "flatten::copy_graph-------------------------------"
					# What will be the target name ?
					set target_file [file join $final_target_dir "[file rootname [file tail $file]].html"]
					# And now cleaning the links
					set final_content [clean_link [rm_root $root_dir] $target_url $target_file $content]
					fas_debug "flatten::copy_graph - ready to write ---------<br>$final_content<br>------------"
					fas_debug "flatten::copy_graph ----> $target_file"

					# File exists ?
					set differ 1
					if {[file readable $target_file]} {
						# read the old file
						if { [ catch { set fid [open $target_file r]} error ] } {
							incr errors
							catch { close fid }
							append errstr "[translate "Error while reading file "] $target_file  - $error
"
						} else {
							set old_content [read $fid]
							close $fid
							# and compare
							if {[string trim $final_content] == [string trim $old_content]} {
								set differ 0
							}
						}
					}
					# Write the file (only if updated)
					if {$differ} {
						if { [ catch { file mkdir $final_target_dir 
							set fid [open $target_file w]} error ] } {
							incr errors
							catch { close fid }
							append errstr "[translate "Error while writing file "] $target_file  - $error"
						} else {
							puts -nonewline $fid $final_content
							close $fid
						}
					}
				}
			}
		}
	}
				
		

	# Going through directory and looking at the files
	proc process_dir { current_env root_dir target_dir relative_dir target_url } {
		upvar $current_env fas_env
		global conf

		# First processing the file of the current directory
		# Skipping CVS directory
		if { [file tail $relative_dir] != "CVS" } {
			copy_graph fas_env $root_dir $target_dir $relative_dir $target_url
		}

		# Now looking for the sub directories
		# Dummy entry for the unset
		set current_dir_env(bad) 0
		fas_debug "flatten::process_dir - $root_dir $target_dir --> $relative_dir"
		# The level variable is just for debug :
		# it allows to see how deep you are in the tree
		# and when you come back (especially when you come back)
		variable level
		fas_debug "flatten::process_dir - level $level"
		incr level

		set dir_list [glob -nocomplain -types {d} -- [file join $root_dir $relative_dir *]]
		fas_debug "flatten::process_dir - current dir_list is $dir_list"
		foreach dir $dir_list {
			# skip CVS directories
			if {([file tail $dir] != "CVS") && ([file tail $dir] != "CVS/")} { 
				# First, I load the corresponding env
				unset current_dir_env
				read_full_env $dir current_dir_env
				if { ![info exists current_dir_env(flatten.ignore)] } {
					set relative_dir [string trimleft [string range $dir [string length $root_dir] end] "/"]
					fas_debug "flatten::process_dir - processing relative_dir $relative_dir"
					#copy_graph current_dir_env $root_dir $target_dir $relative_dir $target_url
					process_dir current_dir_env $root_dir $target_dir $relative_dir $target_url
					#if the directory can be displayed, with a special
					#feature, then I display it and I create a index.html
					#file for this directory
					if { [info exists dir_env(view.comp)] } {
						# It is possible to display the directory
						set menu::done 0
						set treedir::done 0
						array set current_file_env current_dir_env
						set content [display_file dir $dir current_file_env conf -nod]
						set target_file [file join $target_dir $relative_dir "index.html"]
						set final_content [clean_link [rm_root $root_dir] $target_url $target_file $content]
						set final_target_dir [file join $target_dir $relative_dir]
						if { [ catch { file mkdir $final_target_dir 
							set fid [open $target_file w]} error ] } {
							incr errors
							catch { close fid }
							append errstr "[translate "Error while writing file "] $target_file  - $error"
						} else {
							puts -nonewline $fid $final_content
							close $fid
						}
					}
						
				}
			}
		}
		fas_debug "flatten::process_dir - leaving level $level"
		incr level -1
	}

	proc copy_cache_file { root_dir target_dir target_url relative_dir } {
		variable not_graphic_list

		set final_target_dir [file join $target_dir $relative_dir]
		set ori_dir [file join $root_dir $relative_dir]

		set file_list [glob -nocomplain -types {f} -- [file join $ori_dir "*&&&"]]
		fas_debug "flatten::copy_cache_file for $ori_dir found - $file_list"
		foreach file $file_list {
			set file_extension [guess_filetype $file conf fas_env]
			# I ignore file with anything else than &&& as a file extension
			fas_debug "flatten::copy_cache_file : processing $file - extension is $file_extension"
			set extension_position [lsearch -exact $not_graphic_list $file_extension]
			if { $extension_position == -1 } {
				# It is a graphic file, I do not change it
				set target_file $final_target_dir
			} else {
				# it is a txt or tmpl or html file
				file mkdir $final_target_dir
				set target_file [file join $final_target_dir "[file rootname [file tail $file]].html"]
			}
			file mkdir $final_target_dir
			fas_debug "flatten::copy_cache_file $file -> $target_file"
			file copy -force $file $target_file
			# And as I am there, I am also going to clean
			# the file of the false links
			clean_link $real_root_dir $target_url $target_file
		}
	}

	proc clean_link { root_dir target_url file content } {
		global FAS_VIEW_CGI
		global FAS_VIEW_URL
		fas_debug "clean_link -- processing $file"
		fas_debug "clean_link regsub -all =\"${FAS_VIEW_CGI}\?file=$root_dir content $target_url final_content"


		variable not_graphic_list 
		foreach extension $not_graphic_list {
			regsub -all "=\"${FAS_VIEW_CGI}\\\?file=${root_dir}(\[^.\]+)\\.${extension}" $content "=\"${target_url}\\1.html" final_content
			set content $final_content
			regsub -all "=\"${FAS_VIEW_URL}\\\?file=${root_dir}(\[^.\]+)\\.${extension}" $content "=\"${target_url}\\1.html" final_content
			set content $final_content
		}

		#regsub -all "=\"${FAS_VIEW_CGI}\\\?file=${root_dir}(\[^.\]+)\\.txt" $content "=\"${target_url}\\1.html" final_content
		#set content $final_content
		#regsub -all "=\"${FAS_VIEW_CGI}\\\?file=${root_dir}(\[^.\]+)\\.tmpl" $content "=\"${target_url}\\1.html" final_content
		#set content $final_content
		#regsub -all "=\"${FAS_VIEW_URL}\\\?file=${root_dir}(\[^.\]+)\\.txt" $content "=\"${target_url}\\1.html" final_content
		#set content $final_content
		#regsub -all "=\"${FAS_VIEW_URL}\\\?file=${root_dir}(\[^.\]+)\\.tmpl" $content "=\"${target_url}\\1.html" final_content
		#set content $final_content
		regsub -all "=\"${FAS_VIEW_CGI}\\\?file=${root_dir}" $content "=\"${target_url}" final_content
		set content $final_content
		regsub -all "=\"${FAS_VIEW_URL}\\\?file=${root_dir}" $content "=\"${target_url}" final_content
		return $final_content
	}
				
			
	proc process_cache_dir { real_root_dir root_dir target_dir target_url relative_dir } {
		puts "process_cache_dir - $root_dir $target_dir --> $relative_dir"
		# First processing the file of the directory
		copy_cache_file $real_root_dir $root_dir $target_dir $target_url $relative_dir
		set dir_list [glob -nocomplain -types {d} -- [file join $root_dir $relative_dir *]]
		puts "process_cache_dir - found following dirs : $dir_list"
		foreach dir $dir_list {
			if { ![file exists [file join $dir .ignore]] } {
				set relative_dir [string trimleft [string range $dir [string length $root_dir] end] "/"]
				process_cache_dir $real_root_dir $root_dir $target_dir $target_url $relative_dir 
			}
		}
	} 
		
}
