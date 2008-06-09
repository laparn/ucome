# Dependency management for fas_view
# fas_env.tcl and cgi.tcl must be called before
# The idea is the following :
#  * when a file is created a dependancy file is created
#    in a shadow directory (.depend/name of the file),
#  * when a file is asked, the dependancies are checked,
#  * the dependencies are stored in the following way :
#    * a file name and a type
# This is stored in an associative array the keys of which
# are the file name. ( I am not sure that it is a good structure).
# When creating a file, we initialise the dependency list
# then we add the different dependencies.
# The dependencies type are :
#  * file,
#  * always (workout - filename is not important)
#  * env (filename is the name of the real original file). 
#    mtime of the env files (.mana/.val for all dir + .mana/filename).
#  * user : dependancy on who did the request
#  * to be defined

# Finally, we create the file.
# Then, when a file is created, if it exists, the corresponding
# dependencies are checked.

# I am going to try to accumulate dependencies in a comp
# It means that when dependencies are set, if I am in
# a phase after the dependencies where saved, I will accumulate
# in the saved file, as well as in the file.
# Just a try. AL - 8 October 2003

namespace eval fas_depend {
	# associative array with all dependencies
	variable depend
	# I put there all the dependencies for a given file
	variable complete_depend
	set complete_depend ""

	# Array to save dependencies between processing using
	# the dependencies (such as in form)
	variable save_depend
	variable in_saved_dependency_flag

	set in_saved_dependency_flag 0

	global ::DEBUG_PROCEDURES
	eval $::DEBUG_PROCEDURES

	variable shadow_dir
	variable shadow_file
	set shadow_dir ".depend"
	set shadow_file ".val"	

	# depend will be a list
	set depend ""

	variable cache_mtime
	array set cache_mtime ""

	# A flag for saying, if I want to take into account env files (.mana/xxx)
	# for dependencies or not. This process is very long, then in some case,
	# I propose to just drop the calculation.
	variable ENV_DEPENDENCY_FLAG
	set ENV_DEPENDENCY_FLAG 1

	# A flag for testing a simple dependency system : either the final file
	# exists and then it is taken (dependencies are met) else it is work out again.
	variable FAST_DEPENDENCY_FLAG
	set FAST_DEPENDENCY_FLAG 0

	# The name of the final_filename file
	# It allows to set this name at the very beginning
	# and then not to take into account filename change
	variable final_filename_cache_filename
	variable final_filetype_cache_filename

	# The name of the complete dependency file
	# It allows to set this name at the very beginning
	variable complete_dependency_cache_filename

	proc init { } {
		variable complete_depend
		set complete_depend ""
		init_dependencies
		variable cache_mtime
		array set cache_mtime ""
	}

	proc init_dependencies {  } {
		fas_debug "fas_depend::init_dependencies - starting"
		variable depend
		set depend ""
	}

	proc set_dependency { value { type file } } {
		fas_fastdebug {fas_depend::set_dependency - $value -- $type}
		variable depend
		variable complete_depend

		lappend depend [list $value $type]
		lappend complete_depend [list $value $type]
		variable in_saved_dependency_flag
		if $in_saved_dependency_flag {
			fas_fastdebug {fas_depend::set_dependency - also in save_depend - $value -- $type}
			variable save_depend
			lappend save_depend [list $value $type]
		}
		#fas_fastdebug {fas_depend::set_dependency complete_depend is $complete_depend}
	}

	# write the dependencies in .depend/XXX file
	proc write_dependencies { filename } {
		fas_fastdebug {fas_depend::write_dependencies - $filename}
		variable depend

		set filename [dependency_name $filename]
		
		# First extracting the directory
		set current_dir [file dirname $filename]

		if { ![file exists $current_dir] } {
			file mkdir $current_dir
		}

		if { [file writable $filename] || ![file exists $filename] } {
			global ::fas_env
			if { [catch {open $filename w} fid] } {
				fas_display_error "fas_depend.tcl - [translate "Problem while opening "] $filename [translate " for writing."]" ::fas_env
			}
			puts $fid "$depend"
			close $fid
			set depend ""
		}
	}

	proc write_complete_dependency { filename current_env} {
		upvar $current_env fas_env
		# The function to write all dependencies for a given file
		# in the depend directory of the cache
		#set complete_depend_filename [cache_filename depend $filename fas_env]
		variable complete_dependency_cache_filename
		set complete_depend_filename $complete_dependency_cache_filename

		# if the file previously exists, I do nothing
		if { ![file readable $complete_depend_filename] } {
			fas_fastdebug {fas_depend::write_complete_dependencies - complete_depend_filename is $complete_depend_filename}
			set complete_depend_dir [file dirname $complete_depend_filename]
			if { ![file isdirectory $complete_depend_dir] } {
				if { [catch { file mkdir $complete_depend_dir }] } {
					fas_display_error "Could not create [rm_root $complete_depend_dir] for caching full dependencies" fas_env
				}
			}
			if { ![catch {open "$complete_depend_filename" w} fid] } {
				variable complete_depend
				puts $fid $complete_depend
				close $fid
				set complete_depend ""
			} else {
				fas_display_error "fas_depend::write_complete_dependencies- [translate "Could not write complete dependencies"] [rm_root $complete_depend_filename]" fas_env -f $filename
			}
		}
	}

	proc write_final_filetype { filetype } {
		variable final_filetype_cache_filename
		# The function write the type of the final displayed file
		# for this file in the final_filetype directory of the cache
		set final_filetype_filename $final_filetype_cache_filename
		fas_fastdebug {fas_depend::write_final_filetype - final_filetype_filename is $final_filetype_filename}
		if { ![file readable $final_filetype_filename] } {
			fas_fastdebug {fas_depend::write_final_filetype - writing it}
			set final_filetype_dir [file dirname $final_filetype_filename]
			if { ![file isdirectory $final_filetype_dir] } {
				if { [catch { file mkdir $final_filetype_dir }] } {
                                        # Everything is done !! to late for an error !!
                                        # I try stdout
                                        puts "Could not create [rm_root $final_filetype_dirname] for caching full dependencies"
					#fas_display_error "Could not create [rm_root $final_filetype_dirname] for caching full dependencies" fas_env
				}
			}
			if { ![catch {open "$final_filetype_filename" w} fid] } {
				puts -nonewline $fid $filetype
				close $fid
			} else {
                                puts "fas_depend::write_final_filetype - [translate "Could not write final filetype"] [rm_root $final_filetype_filename]"
				#fas_display_error "fas_depend::write_final_filetype - [translate "Could not write final filetype"] [rm_root $final_filetype_filename]" fas_env -f $filename
			}
		}
	}

	proc write_final_filename { current_env final_filename } {
		upvar $current_env fas_env
		variable final_filename_cache_filename
		# The function write the type of the final displayed file
		# for this file in the final_filetype directory of the cache
		fas_fastdebug {fas_depend::write_final_filename - final_filename is $final_filename , final_filename_cache_filename $final_filename_cache_filename}
		if { ![file readable $final_filename_cache_filename] } {
			set final_filename_cache_dir [file dirname $final_filename_cache_filename]
			if { ![file isdirectory $final_filename_cache_dir] } {
				if { [catch { file mkdir $final_filename_cache_dir }] } {
                                        puts "Could not create [rm_root $final_filename_cache_dir] for caching full dependencies"
					#fas_display_error "Could not create [rm_root $final_filename_cache_dir] for caching full dependencies" fas_env
				}
			}
			if { ![catch {open "$final_filename_cache_filename" w} fid] } {
				puts -nonewline $fid $final_filename
				close $fid
			} else {
                                puts "fas_depend::write_final_filename - [translate "Could not write final final_filename_cache_filename"] [rm_root $final_filename_cache_filename]"
				#fas_display_error "fas_depend::write_final_filename - [translate "Could not write final final_filename_cache_filename"] [rm_root $final_filename_cache_filename]" fas_env
			}
		}
	}
	proc get_final_filename {  } {
		variable final_filename_cache_filename
		# The function write the type of the final displayed file
		# for this file in the final_filetype directory of the cache
		fas_fastdebug {fas_depend::get_final_filename - final_filename_cache_filename $final_filename_cache_filename}
		if { ![catch {open "$final_filename_cache_filename" r} fid] } {
			set final_filename [read $fid]
			close $fid
			return $final_filename
		} else {
			return ""
		}
	}
	proc get_final_filetype { current_env filename } {
		upvar $current_env fas_env
		# The function write the type of the final displayed file
		# for this file in the final_filetype directory of the cache
		set final_filetype_filename [cache_filename final_filetype $filename fas_env]
		fas_fastdebug {fas_depend::get_final_filetype - final_filetype_filename is $final_filetype_filename}
		if { ![catch {open "$final_filetype_filename"} fid] } {
			set filetype [read $fid ]
			close $fid
		} else {
			return ""
		}
		return $filetype
	}


	proc dependency_name { filename } {
		variable shadow_dir
		variable shadow_file

		if { [file isdirectory $filename] } {
			# fas_debug "write_all_env - $dir is a directory"
			set final_filename [file join $filename $shadow_dir $shadow_file]
		} else {
			set current_dir [file dir $filename ]
			set current_file [file tail $filename]
			set final_filename [file join $current_dir $shadow_dir $current_file]
		}

		return $final_filename
	}

	proc check_simple_dependencies { target_file } {
		fas_fastdebug {fas_depend::check_simple_dependencies : target : $target_file}
	
	
		# if there are no dependency list
		# I consider that yes it must be processed again
		set dependency_name [dependency_name $target_file]

		return [check_dependencies $target_file $dependency_name]
	}

	proc check_complete_dependencies { filename current_env } {
		upvar $current_env fas_env
		fas_debug "fas_depend::check_complete_dependencies : entering"

		set dependency_name [cache_filename depend $filename fas_env]
		
		# I store the name for the end
		variable complete_dependency_cache_filename
		set complete_dependency_cache_filename $dependency_name

		# I also prepare the final_filename
		variable final_filename_cache_filename
		set final_filename_cache_filename [cache_filename final_filename $filename fas_env]
		# and the final_filetype
		variable final_filetype_cache_filename
		set final_filetype_cache_filename [cache_filename final_filetype $filename fas_env]

		#set final_filetype_filename [cache_filename final_filetype $filename fas_env]
		# The final filetype does not exist, then I send back 1
		set final_filetype [get_final_filetype fas_env $filename]
		if { $final_filetype == "" } {
			fas_fastdebug {fas_depend::check_complete_dependencies : could not get final_filetype - return ''}
			return 1
		}

		# From there I should be able to guess the name of the final file
		set final_filename [cache_filename $final_filetype $filename fas_env]
		fas_fastdebug {fas_depend::check_complete_dependencies : final_filename => $final_filename}

		# Fast dependency ?
		variable FAST_DEPENDENCY_FLAG
		if { $FAST_DEPENDENCY_FLAG } {
			# Found file ?
			if { [file readable $final_filename] } {
				# Yes nothing to do
				fas_fastdebug {fas_depend::check_complete_dependencies : $final_filename found}
				fas_fastdebug {fas_depend::check_complete_dependencies : FAST_DEPENDENCY mode, return 0}
				return 0
			} else {
				fas_fastdebug {fas_depend::check_complete_dependencies : FAST_DEPENDENCY mode, return 1}
				return 1
			}
		}
				
		# Now loading all the dependencies
		set dependency_name [cache_filename depend $filename fas_env]
		fas_fastdebug {fas_depend::check_complete_dependencies - $dependency_name}
		if { [file readable $dependency_name] } {
			set fid [open $dependency_name]
			set dependency_list [read $fid]
			close $fid
			return [check_dependencies_from_list $final_filename $dependency_list]
		} else {
			return 1
		}
	}

	# if the target_file must be processed again, then this function
	# will send back 1, else it will send back 0
	proc check_dependencies { target_file args } {
		fas_fastdebug {fas_depend::check_dependencies : target : $target_file}
	
		# I am not so sure of this initialisation value
		set result 0
	
		set dependency_list ""
		# if there are no dependency list
		# I consider that yes it must be processed again
		set dependency_name [dependency_name $target_file]
		fas_fastdebug {fas_depend::check_dependencies - $dependency_name}
		if { [file readable $dependency_name] } {
			set fid [open $dependency_name]
			set dependency_list [read $fid]
			close $fid
			set result [check_dependencies_from_list $target_file $dependency_list]
		} else {
			#set result 1
			return 1
		}

		fas_fastdebug {fas_depend::check_dependencies target : $target_file => result is $result (0 - nothing to do, 1 process again}
		return $result
	}

	# This function will use a dependency list 
	# for knowing which dependency to test for a target file
	# return 0, if I can use the cache, return 1 if it must be worked out again
	proc check_dependencies_from_list { target_file dependency_list } {
		fas_fastdebug {fas_depend::check_dependencies_from_list : target : $target_file - dependency_list $dependency_list}
		
		if { [catch {set target_file_date [file mtime $target_file]} ] } {
			fas_fastdebug {fas_depend::check_dependencies_from_list : problem getting date for $target_file}
			# The target file does not exist
			# It must be processed again
			return 1
		}

		# I introduce a cache. Once a dependency was tested
		# I do not need to test it again. Then I store it
		# in the following array
		array set cache_dependency_array ""
		#fas_debug "fas_depend::check_dependencies target_file_date : $target_file_date"
		foreach dependency $dependency_list {
			# For file and env, file is a file name
			# In the case of user, it is the user name
			set file [lindex $dependency 0]
			set type [lindex $dependency 1]
			if { ![info exists cache_dependency_array($file###$type)] } {
				fas_fastdebug {fas_depend::check_dependencies_from_list - checking file $file type $type}
				switch -exact -- $type {
					"file" {
						#fas_debug "fas_depend::check_dependencies - file $file - mtime [file mtime $file] - targ < file => [expr $target_file_date < [file mtime $file]]"
						if { [file exists $file] } {
							# if the target is older than the file, it must
							# be worked out again (1 added)
							# target_time < time
							#incr result [expr $target_file_date < [file mtime $file]]
							if { $target_file_date < [file mtime $file] } {
								return 1
							}
						} else {
							# the file does no more
							# exist, the dependency
							# is not met
							#incr result
							return 1
						}
					}
					"always" {
						#set result 1
						return 1
					}
					"env" {
						variable ENV_DEPENDENCY_FLAG
						if {$ENV_DEPENDENCY_FLAG } {
							set current_mtime_full_env [mtime_full_env $file]
							#fas_debug "fas_depend::check_dependencies - env $file - mtime_full_env current_mtime_full_env - targ < file => [expr $target_file_date < $current_mtime_full_env]"
							#incr result [expr $target_file_date < [mtime_full_env $file] ]
							if {  $target_file_date < $current_mtime_full_env  } {
								return 1
							}
						}
					}
					"user" {
						#fas_debug "fas_depend::check_dependencies - user - $current_user   - file == current_user => [expr $file == $current_user]"
						set current_user ${user::name}
						#incr result [expr $file == $current_user]
						if { $file == $current_user } {
							return 1
						}
					}
					default {
						fas_fastdebug {fas_depend::check_dependencies - unknown type $type for file $file}
					}
				}
				set cache_dependency_array(${file}###${type}) ""

			}
		}

		fas_fastdebug {fas_depend::check_dependencies_from_list target : $target_file => result is 0 (0 - nothing to do, 1 process again}
		return 0
	}

	proc check_single_dependency { target_file_date file type } {
		fas_fastdebug {fas_depend::check_single_dependency - checking file $file type $type}
		switch -exact -- $type {
			"file" {
				#fas_debug "fas_depend::check_dependencies - file $file - mtime [file mtime $file] - targ < file => [expr $target_file_date < [file mtime $file]]"
				if { [file exists $file] } {
					# if the target is older than the file, it must
					# be worked out again (1 added)
					# target_time < time
					#incr result [expr $target_file_date < [file mtime $file]]
					if { $target_file_date < [file mtime $file] } {
						return 1
					} else {
						return 0
					}
				} else {
					# the file does no more
					# exist, the dependency
					# is not met
					#incr result
					return 1
				}
			}
			"always" {
				#set result 1
				return 1
			}
			"env" {
				set current_mtime_full_env [mtime_full_env $file]
				#fas_debug "fas_depend::check_dependencies - env $file - mtime_full_env current_mtime_full_env - targ < file => [expr $target_file_date < $current_mtime_full_env]"
				#incr result [expr $target_file_date < [mtime_full_env $file] ]
				if {  $target_file_date < $current_mtime_full_env  } {
					return 1
				} else {
					return 0
				}
			}
			"user" {
				#fas_debug "fas_depend::check_dependencies - user - $current_user   - file == current_user => [expr $file == $current_user]"
				set current_user ${user::name}
				#incr result [expr $file == $current_user]
				if { $file == $current_user } {
					return 1
				} else {
					return 0
				}
			}
			default {
				fas_fastdebug {fas_depend::check_dependencies - unknown type $type for file $file}
				return 0
			}
		}
		return 0
	}

	# Internal save and restore functions for the depend
	# array. This is used for the composite type, to
	# save and restore the dependencies before getting a file
	# to be used in such a composite file.
	proc save_dependencies { } {
		fas_debug "fas_depend::save_dependencies"
		variable depend
		variable save_depend

		set save_depend $depend

		fas_fastdebug {fas_depend::save_dependencies - save_depend - $save_depend}
		variable in_saved_dependency_flag
		set in_saved_dependency_flag 1
	}

	proc restore_dependencies { } {
		fas_debug {fas_depend::restore_dependencies}
		variable depend
		variable save_depend

		set depend $save_depend

		fas_fastdebug {fas_depend::restore_dependencies - depend - $depend}
		variable in_saved_dependency_flag
		set in_saved_dependency_flag 0
	}
}
				
