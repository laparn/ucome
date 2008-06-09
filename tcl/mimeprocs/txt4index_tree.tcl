lappend filetype_list "txt4index_tree"

namespace eval txt4index_tree {
	# At the end of indexing I set done to 1.
	# I will use it when changing of state
	set done 0
	set level 0

	set result_string ""

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	set errors 0
	set errstr ""

	proc new_type { current_env filename } {
		# At the end of indexing, we will display edit_form
		# on the root_directory 
 		set result tmpl
		variable done
		set done 1
		fas_debug "txt4index_tree::new_type -> $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list tmpl]
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
		lappend env_list [list "txt4index_tree.start" "Directory from which to start the indexing." admin]
		return $env_list
	}

	proc init { } {
		variable result_string
		set result_string ""
	}

	proc 2tmpl { current_env filename } {
		upvar $current_env fas_env

		return [2fashtml fas_env $filename]
	}

	# Name of the directory where all txt4index files are stored
	proc get_txt4index_tree_dir { current_env } {
		upvar $current_env fas_env
		if { [info exists fas_env(txt4index.dir)] } {
			set target_dir [add_root $fas_env(txt4index.dir)]
		} else {
			set root_directory "[add_root [fas_name_and_dir::get_txt4index_tree_start_dir fas_env]]"
			set target_dir [cache_filename txt4index_tree $root_directory fas_env -no_extension]
		}
		return $target_dir
	}


	# We start from the root_dir and create the txt4index
	# for the files of this dir and subdir.
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		fas_debug "txt4index_tree::2fashtml $filename"
		global FAS_VIEW_CGI
		
		# First, what will I txt4index ?
		set root_directory "[add_root [fas_name_and_dir::get_txt4index_tree_start_dir fas_env]]"

		# Always do again and again
		fas_depend::set_dependency 1 always

		# Then, what is the index target directory ?
		# (we will just create only one index file in this directory)
		set target_dir [get_txt4index_tree_dir fas_env]
		fas_debug "txt4index::2fashtml - root_directory : $root_directory - target_dir : $target_dir"

		# OK now in theory, I can start the process

		# index all the site
		process_dir fas_env $root_directory $target_dir ""
		global_init
		fas_depend::set_dependency 1 always
		#set ::menu::done 0
		set _cgi_uservar(action) "txt4index_tree"
		variable result_string
		return "$result_string"
	}

	proc txt4index_files_in_dir { current_env root_dir target_dir relative_dir} {
		fas_debug "txt4index_tree::txt4index_files_in_dir - entering - root_dir => $root_dir , target_dir => $target_dir , relative_dir => $relative_dir"
		upvar $current_env fas_env
		set final_target_dir [file join $target_dir $relative_dir]
		set ori_dir [file join $root_dir $relative_dir]

		variable result_string

		set not_graphic_list  [flatten::get_not_graphic_list]
		set file_list [glob -nocomplain -types {f} -- [file join $ori_dir *]]
		fas_debug "txt4index_tree::txt4index_files_in_dir found - $file_list"
		global DEBUG
		set ORI_DEBUG $DEBUG
		global conf
		foreach file $file_list {
			set original_file_name $file
			read_full_env $file current_file_env
			set file_type [guess_filetype $file conf current_file_env ]
			if { ![info exists current_file_env(txt4index.ignore)] &&  $file_type != "dir" } {
				fas_debug "txt4index::txt4index_files_in_dir - filetype of $file is $file_type"
				if { [lsearch $not_graphic_list $file_type] == -1 } {
					# it is a graphic file, I do nothing,
					# because I don't want to index graphic files.
					# maybe that later we will index graphic files commentaries.
				} else {
					# it is not a graphic file, so I convert it to txt
					# First full reinitialisation
					# And debug stop
					global IN_COMP ERROR_LOOP errors errstr
					set ORI_IN_COMP $IN_COMP
					set IN_COMP 0
					set ERROR_LOOP 0
					set errors 0
					set errstr ""
					global _cgi_uservar
					unset _cgi_uservar
					# I startup all initialisation procedures
					global filetype_list
					foreach filetype $filetype_list {
						if { [llength [info command ::${filetype}::init]] > 0 }  {
							if { $filetype != "txt4index_tree" } {
								# fas_debug "txt4index_tree::txt4index_files_in_dir - ::${filetype}::init"
								::${filetype}::init
							}
						}
					}

					set _cgi_uservar(target) "txt4index"
					#set DEBUG 0
					global DEBUG_STRING
					set DEBUG_STRING ""

					fas_debug "txt4index_tree::txt4index_files_in_dir - getting $file"
					set content [display_file $file_type $file current_file_env conf -nod]
					# I re-enable debug
					#set DEBUG $ORI_DEBUG
					if { $errors > 0 } {
						fas_debug "txt4index_tree::txt4index_files_in_dir error on $file => $errstr"
						append result_string "<BR>[translate "Error on "]${file}<PRE>$errstr</PRE>"
					} else {
						fas_debug "txt4index_tree::txt4index_files_in_dir -------------content----------"
						fas_debug "$content"
						fas_debug "txt4index_tree::txt4index_files_in_dir -------------------------------"
						# What will be the target name ?
						set target_file [file join $final_target_dir "[file tail $file]"]

						# Write the file 
						if { [catch {file mkdir $final_target_dir} ] } {
							append result_string "<BR>[translate "Error on "]${file}<BR>[translate "Could not create "] $final_target_dir<BR>"
						} elseif { [
							 catch {
							 	fas_debug "txt4index_tree:txt4index_files_in_dir - writing $target_file"
								set fid [open $target_file w]
								puts -nonewline $fid $content
								close $fid 
							 	fas_debug "txt4index_tree:txt4index_files_in_dir - $target_file was successfully written"
							} ] 
						} {
							append result_string "<BR>\n[translate "Error on "]${file}<BR>[translate "Problem writing "] $target_file"
						} else {
							append result_string "<BR>\n[translate "txt4index file created for "]$file"
						}
					}
					#unset _cgi_uservar
					set IN_COMP $ORI_IN_COMP
				}
			}
		}
	}

	proc global_init { } {
		fas_debug "txt4index_tree::global_init - global_init"
		# I startup all initialisation procedures
		global filetype_list
		foreach filetype $filetype_list {
			if { [llength [info command ::${filetype}::init]] > 0 }  {
				if { $filetype != "txt4index_tree" } {
					fas_debug "txt4index_tree::global_init - ::${filetype}::init"
					::${filetype}::init
				}
			}
		}
	}

	# Going through directory and looking at the files
	proc process_dir { current_env root_dir target_dir relative_dir } {
		upvar $current_env fas_env

		variable result_string
		# First processing the file of the current directory
		# Skipping CVS directory
		txt4index_files_in_dir fas_env $root_dir $target_dir $relative_dir

		# Now looking for the sub directories
		# Dummy entry for the unset
		set current_dir_env(bad) 0
		fas_debug "txt4index_tree::process_dir - $root_dir $target_dir --> $relative_dir"
		# The level variable is just for debug :
		# it allows to see how deep you are in the tree
		# and when you come back (especially when you come back)
		variable level
		fas_debug "txt4index::process_dir - level $level"
		incr level

		set dir_list [glob -nocomplain -types {d} -- [file join $root_dir $relative_dir *]]
		fas_debug "txt4index::process_dir - current dir_list is $dir_list"
		foreach dir $dir_list {
			# skip CVS directories
			if {([file tail $dir] != "CVS") && ([file tail $dir] != "CVS/")} { 
				# First, I load the corresponding env
				unset current_dir_env
				read_full_env $dir current_dir_env
				if { ![info exists current_dir_env(txt4index.ignore)] } {
					append result_string "<br>\n[translate "Processing "]$dir"
					set relative_dir [string trimleft [string range $dir [string length $root_dir] end] "/"]
					fas_debug "txt4index_tree::process_dir - processing relative_dir $relative_dir"
					process_dir current_dir_env $root_dir $target_dir $relative_dir
				}
			}
		}
		fas_debug "txt4index_tree::process_dir - leaving level $level"
		incr level -1
		# I need to "clean" a little before coming back
		# Especially the target, because during txt4index_files_in_dir
		# everything was changed
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(action) txt4index_tree
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to edit a content. It must be a file."]</b></center></body></html>"
	}

}
