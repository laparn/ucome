set shadow_dir ".mana"
set shadow_file ".val"
# Read in the file $file, an array and put it in current_env
# file a file name
# env an environment variable
proc read_env { file current_env } {
	#fas_debug "read_env - reading $file"
	upvar $current_env env
	if { [file readable $file] } {
		if { ![catch {open $file} fid] } {
			if [ catch { array set env [read $fid] } error ] {
				error "fas_env.tcl - read_env - [translate "Problem while reading environment variables for file :"] $file"
			}
			close $fid
		}
	} 
}

# args may be -anything which is equal to -depend
# in this case files are searched, read or written from the
# .depend directory
proc read_dir_env { dir current_env args } {
	upvar $current_env env

	if { [llength $args] > 0 } {
		set shadow_type "depend"
		set shadow_dir ".depend"
	} else {
		global shadow_dir
	}
	global shadow_file
	
	# in fact dir may be a file or a directory
	# if it is a directory, I take the values from
	# the file .mana/.val in this directory
	#fas_debug "read_dir_env - trying to read $dir"
	# fas_debug "read_dir_env - [file join $dir .mana/.val]"
	if { [file readable $dir] && ![file isdirectory $dir] } {
		# So here I directly read the env in file
		# In fact, I must look in .mana/filename
		set current_dir [file dir $dir]
		set filename [file tail $dir]
		# If I can not read a file I do not bother
		#fas_debug "read_dir_env - read_env [file join $current_dir $shadow_dir $filename]"
		read_env [file join $current_dir $shadow_dir $filename] env 
		#read_env $dir env
	} elseif { [file readable [file join $dir ${shadow_dir} ${shadow_file}]] } {
		#fas_debug "read_dir_env read_env [file join $dir $shadow_dir $shadow_file]"
		read_env [file join $dir $shadow_dir $shadow_file] env
	} else {
		fas_debug "read_dir_env could not read [file join $dir ${shadow_dir} ${shadow_file}]"
	}
}


# Send back the mtime of the env file or of a directory
proc mtime_dir_env { dir } {
	global shadow_dir
	global shadow_file

	set mtime -1
	# in fact dir may be a file or a directory
	# if it is a directory, I take the values from
	# the file .mana/.val in this directory

	# Hereunder is a very clean code and very slow !
	# I search for a quicker solution
	if { [file readable $dir] && ![file isdirectory $dir] } {
		# So here I directly read the env in file
		# In fact, I must look in .mana/filename
		set current_dir [file dir $dir]
		set filename [file tail $dir]
	
		set shadow_env_file [file join $current_dir $shadow_dir $filename]
		if { [file readable $shadow_env_file] } {
			set mtime [file mtime $shadow_env_file]
		}	
	} else {
		set mtime [mtime_only_dir_env $shadow_dir $shadow_file $dir]
	}
	# A slower solution 
	#set current_dir [file dir $dir]
	#set filename [file tail $dir]
	
	#set shadow_env_file [file join $current_dir $shadow_dir $filename]
	#if { [catch {set mtime [file mtime $shadow_env_file]} ] } {
		# There was a problem, then I take the dir value
	#	set shadow_env_file [file join $dir $shadow_dir $shadow_file]
	#	catch { set mtime [file mtime $shadow_env_file ] }
	#}
	return $mtime
}
# Send back the mtime of the .mana of a directory
proc mtime_only_dir_env { shadow_dir shadow_file dir } {
	set mtime -1
	# in fact dir may be a file or a directory
	# if it is a directory, I take the values from
	# the file .mana/.val in this directory

	# Hereunder is a very clean code and very slow !
	# I search for a quicker solution
	set shadow_env_file [file join $dir $shadow_dir $shadow_file]
	if { [file readable $shadow_env_file] } {
		set mtime [file mtime $shadow_env_file ]
	}
	return $mtime
}


# THIS IS OBSOLETE PLEASE USE read_full_env
# starting from root and till the file or directory end
# load the different files in the same variable
proc read_all_env { root end current_env } {
	upvar $current_env env
	# First end must start with root,
	# Is it the case ?
	set root_list [file split $root]
	set end_list [file split $end]
	set result_list ""
	# start_index is the index where dir_root and dir_end
	# differs
	set start_index 0
	set ROOT_OK 1
	foreach dir_root $root_list dir_end $end_list {
		#puts "$dir_root -- $dir_end-"
		# Does dir_root and dir_end differs ?
		if { $dir_root != $dir_end } {
			# I need to know what comes after root
			if { $ROOT_OK }  {
				# The first time element differs,
				# result_list is processed as being the end
				# of end_list from the current_index
				#puts " start_index : $start_index"
				set result_list [lrange $end_list $start_index end]
			}
			# So now I set a flag for no more setting
			# result_list
			set ROOT_OK "0"
			#puts "NOT EQUAL"
		} 
		incr start_index 
	}
	#puts "result_list => $result_list"
	# In result_list there is the part of end_list that is useful 
	# I can start to extract the different files
	set current_dir_list $root_list
	foreach dir $result_list {
		lappend current_dir_list $dir
		set real_dir [eval file join $current_dir_list]
		#puts "real_dir => $real_dir"
		read_dir_env $real_dir env
	}
	#parray env
}

# The goal is to eliminate the root part at start of the filename 
proc suppress_root { root filename } {
	# First end must start with root,
	# Is it the case ?
	set root_list [file split $root]
	set file_list [file split $filename]
	set result_list ""
	# start_index is the index where dir_root and dir_end
	# differs
	set start_index 0
	set ROOT_OK 1
	foreach dir_root $root_list dir_end $file_list {
		#puts "$dir_root -- $dir_end-"
		# Does dir_root and dir_end differs ?
		if { $dir_root != $dir_end } {
			# I need to know what comes after root
			if { $ROOT_OK } {
				# The first time element differs,
				# result_list is processed as being the end
				# of end_list from the current_index
				#puts " start_index : $start_index"
				set result_list [lrange $file_list $start_index end]
			}
			# So now I set a flag for no more setting
			# result_list
			set ROOT_OK "0"
			#puts "NOT EQUAL"
		} 
		incr start_index 
	}
	if { [llength $result_list] != 0 } {
		return "[eval file join $result_list]"
	} else {
		return ""
	}
}

# starting from / and till the file or directory end
# load the different files in the same variable
proc read_full_env { end current_env } {
	#fas_debug "entering read_full_env"
	upvar $current_env env
	# First end must start with root,
	# Is it the case ?
	set end_list [file split $end]
	set current_dir_list ""
	foreach dir $end_list {
		lappend current_dir_list $dir
		set real_dir [eval file join $current_dir_list]
		#fas_debug "real_dir => $real_dir"
		read_dir_env $real_dir env
	}
}

# Send back the most recent date in mtime format of any
# environment file for this file.
# The directories are parsed from the first to the last
# and to the file.
proc deprecated_mtime_full_env { end } {
	#fas_debug "Entering mtime_full_env"
	# First end must start with root,
	# Is it the case ?
	global shadow_dir
	global shadow_file

	if { [info exists ::fas_depend::cache_mtime($end)] } {
		set mtime $::fas_depend::cache_mtime($end)
	} else {
		set without_root_end [rm_root $end]
		set mtime 0
		set end_list [file split $without_root_end]
		set current_dir_list ""
		set real_dir "[add_root ""]"
		# Till the last, I know that they are directories
		foreach dir [lrange $end_list 0 end-1] {
			#lappend current_dir_list $dir
			set real_dir [file join $real_dir $dir]
			#fas_debug "real_dir => $real_dir"
			set mtime_current_dir [mtime_only_dir_env $shadow_dir $shadow_file $real_dir]
			if { $mtime_current_dir > $mtime } {
				set mtime $mtime_current_dir
			}
		}
		# Now the last part file or directory
		set dir [lindex $end_list end]
		set real_dir [file join $real_dir $dir]
		set mtime_current_dir [mtime_dir_env $real_dir]
		if { $mtime_current_dir > $mtime } {
			set mtime $mtime_current_dir
		}
		set ::fas_depend::cache_mtime($end) $mtime
	}
	return $mtime
}
			
# Send back the most recent date in mtime format of any
# environment file for this file.
# The directories are parsed from the first to the last
# and to the file.
# Speed optimized version
proc mtime_full_env { end } {
	#fas_debug "Entering mtime_full_env"
	# First end must start with root,
	# Is it the case ?
	global shadow_dir
	global shadow_file

	if { [info exists ::fas_depend::cache_mtime($end)] } {
		set mtime $::fas_depend::cache_mtime($end)
	} else {
		#fas_fastdebug {fas_env::optimized_mtime_full_env - starting with $end}
		set FOUND 0
		set current_dir $end
		
		set root [get_root]
		set end [file normalize $end]
		set start_mtime 0
		set start_mtime_dir $root

		# I try to find a directory for which the mtime
		# was previously worked out. If I find it
		# I start to get the mtime from it
		while { $current_dir != "$root" && !$FOUND } {
			#fas_fastdebug {fas_env::optimized_mtime_full_env - checking cache_mtime for $current_dir}
			if { [info exists ::fas_depend::cache_mtime($current_dir)] } {
				set start_mtime_dir $current_dir
				set start_mtime $::fas_depend::cache_mtime($current_dir)
				set FOUND 1
				#fas_fastdebug {fas_env::optimized_mtime_full_env - found cache_mtime for $current_dir => $start_mtime}
			}
			set current_dir [file dirname $current_dir]
		}

		set without_root_end [rm_dir $end $start_mtime_dir]
		set mtime $start_mtime
		set end_list [file split $without_root_end]

		set current_dir_list ""
		set real_dir "$start_mtime_dir"
		# Till the last, I know that they are directories
		foreach dir [lrange $end_list 1 end-1] {
			set real_dir [file join $real_dir $dir]
			#fas_fastdebug {optimized_mtime_dir_env - real_dir => $real_dir}
			set mtime_current_dir [mtime_only_dir_env $shadow_dir $shadow_file $real_dir]
			if { $mtime_current_dir > $mtime } {
				set mtime $mtime_current_dir
			}
			set ::fas_depend::cache_mtime($real_dir) $mtime
		}
		# Now the last part file or directory
		set dir [lindex $end_list end]
		set real_dir [file join $real_dir $dir]
		set mtime_current_dir [mtime_dir_env $real_dir]
		if { $mtime_current_dir > $mtime } {
			set mtime $mtime_current_dir
		}
		set ::fas_depend::cache_mtime($end) $mtime
		#fas_fastdebug {fas_env::optimized_mtime_full_env - finished => $mtime}
	}
	return $mtime
}
	
# Write an env file - simply just write it
proc write_env { file current_env } {
	upvar $current_env env
	fas_debug "write_env -> $file"

	# First extracting the directory
	set current_dir [file dirname $file]

	if { ![file exists $current_dir] } {
		file mkdir $current_dir
	}

	if { [file writable $file] || ![file exists $file] } {
		#catch {
			fas_debug "write_env - writing [array get env] in $file" 
			set fid [open $file w]
			puts $fid "[array get env]"
			close $fid
		#}
	} else {
		error "Could not write $file"
	}
}

# Write all env file.
# If we give a dir name then it writes within .mana/.val
# If we give a filename then it writes in dir_name/.mana/file_name
proc write_all_env { dir current_env args } {
	upvar $current_env env

	if { [llength $args] > 0 } {
		set shadow_type "depend"
		set shadow_dir ".depend"
	} else {
		global shadow_dir
	}
	global shadow_file
	fas_debug "write_all_env - $dir - $shadow_dir - $shadow_file"
	if { [file isdirectory $dir] } {
		# fas_debug "write_all_env - $dir is a directory"
		write_env [file join $dir $shadow_dir $shadow_file] env
	} else {
		set current_dir [file dir $dir]
		set current_file [file tail $dir]
		#fas_debug "write_all_env - $dir is a file"
		write_env [file join $current_dir $shadow_dir $current_file] env
	}
}

# Send back the name of the env. By default use .mana/.val ,
# If it is of type depend (if args exists). Then shadow_dir is xxxx/.depend ,
proc env_filename { dir args} {
	if { [llength $args] } {
		set shadow_dir .depend
	} else {
		global shadow_dir
	}

	global shadow_file

	if { [file isdirectory $dir] } {
		set result [file join $dir $shadow_dir $shadow_file]
	} else {
		set current_dir [file dir $dir]
		set current_file [file tail $dir]
		set result [file join $current_dir $shadow_dir $current_file]
	}
	return $result
}

# From a root (pdf.cgi_uservar for example) take all values and put it in the env
# ex : there is
# pdf.cgi_uservar.txt.view.comp in fas_env
# I take the value and put it in txt.view.comp
proc down_stage_env { current_env env_root } {
	upvar $current_env fas_env

	set stage_env_name_list [array names fas_env "${env_root}*"]
	fas_debug "fas_env::down_stage_env - names -> $stage_env_name_list"
	set start_length [string length ${env_root}]
	foreach name $stage_env_name_list {
		set final_name [string range $name $start_length end]
		set fas_env($final_name) $fas_env($name)
		fas_debug "fas_env::downstage_env $name -> $final_name : $fas_env($name)"
	}
}
