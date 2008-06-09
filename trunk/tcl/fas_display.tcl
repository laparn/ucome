set BUS_GESTION_ERROR 0
set FATAL_ERROR 0
set ORDER_ERROR_CODE 1056

# Name : display_file
# The main procedure for displaying ANY file type.
# In other words, it changes a file into html, gif, jpeg or pdf.
# If the file type is correctly handled, then
# it may be cached.
# The following conf variables are waited :
# conf(newtype.$filetype) (also resultype in the following)
# fas_env(cache.$filetype) or fas_env(cache)/$filetype/ :
#                the place where cached files are stored
# fas_env(file_index_dir) : the name of a file to display when current_directory
# is called
# The behaviour should be the following :
#   * we want to display a file which has a known filetype
#   * if the file is a directory, then either there is fas_env(file_index_dir)
#     to indicate the base file to use for this directory,
#     or we append index.txt to the directory.
#   * either it is possible to display it directly (it is html) or not
#   * if it is not html, then we try to convert it and cached it
#     until it is html, else we try to display it directly.
#     => any created filetype must provide a display function.
# When the nodisplay (-nod) option is activated, instead of displaying
# the file, its final content is sent back.

proc display_file { filetype filename current_env current_conf args} {
	fas_debug "fas_display.tcl - display_file $filetype $filename $args"
	upvar $current_env fas_env
	upvar $current_conf conf
	set PROCESS_FLAG 1
	set filename [expand_path $filename]
	# Set to 1 if I want no cache
	set NOCACHE 0
	# Please do not display the final result
	set NODISPLAY 0
	set CONTENT_FLAG 0
	set flag_args ""

	set state parse_args
	foreach arg $args {
		switch -exact -- $state {
			parse_args {
				switch -glob -- $arg {
					-noc* {
						#nocache
						set NOCACHE 1
						append flag_args "-noc"
					}
					-nod* {
						#nodisplay
						set NODISPLAY 1
						append flag_args " -nod"
					}
					-content {
						set state CONTENT
						set CONTENT_FLAG 1
					}
				}
			}
			CONTENT {
				set current_content $arg
				set state parse_args
			}
		}
	}

	fas_debug "fas_display.tcl - display_file $filetype $filename $args - NOCACHE $NOCACHE NODISPLAY $NODISPLAY"
	# I append to the current filetype_list the current filetype
	lappend conf(filetype_list) $filetype
	# if I am in the NOCACHE case, then I load the file, and I switch to display_content
	if { $NOCACHE } {
		# First what is the real filename
		set real_filename [fas_name_and_dir::get_real_filename $filetype $filename fas_env]
		main_log "Reading $real_filename and displaying it"

		# Now loading the file
		if { [catch { open $real_filename } fid] } {
			fas_display_error "fas_display.tcl - display_file $filetype $filename $args - [translate "Could not open "] $real_filename [translate " for loading "]" fas_env -f $filename
		} else {
			set content [read $fid]
			close $fid
			# Test of an optimized version
			#eval display_content \$filetype \$content fas_env conf $args
			if 1 [concat [list display_content $filetype $content fas_env conf ] $args]
		}
		return ""
	}
	
	# if there are no cache directory, the command
	# must be processed
	fas_debug "fas_display.tcl - display_file : filetype -> $filetype"
	#set error_resultype [catch { set resulttype [${filetype}::new_type fas_env $filename]} ]
	set resulttype [${filetype}::new_type fas_env $filename]
	fas_debug "fas_display.tcl - ${filetype}::new_type returned \'$resulttype\'"
	if { $resulttype != "" } {

		fas_debug "fas_display.tcl - display_file $filetype $filename $args - resulttype -> $resulttype"
		# filename must be transformed from filetype into conf(newtype.filetype)
		# There is a planned cache directory
		set output_filename "[cache_filename $resulttype $filename fas_env]"
		#main_log "Changing $filename of type $filetype into $resulttype"
		#if { [file readable $output_filename] } {
		#	fas_debug "fas_display.tcl - display_file - $output_filename is readable"
			# So now I am checking the dependencies of the output_filename
			# AL - 30/12/2004 - with check_complete_dependencies, there is no
			# more any use to do a partial check. If I arrive here, I do the
			# work out, and that's all
			#if { ![fas_depend::check_dependencies $output_filename] } {
				# the output file exists, there is nothing
				# to do but to output it.
			#	if { !$NODISPLAY } {
			#		eval display_file \$resulttype \$filename fas_env conf $args
			#	} else {
			#		fas_debug "fas_display.tcl::display_file - dependency not met, returning display_file content for $resulttype $filename fas_env conf $args"
			#		return "[eval display_file \$resulttype \$filename fas_env conf $args]"
			#	}
			#	set PROCESS_FLAG 0
			#} else {
				# The cache is older than the file
				# the file must be processed again
				# and cached.
		#		fas_debug "fas_display.tcl - fas_display - [translate "Dependencies are not met for "] $filename - [translate "processing again"]"
		#		if { !$NODISPLAY } {
		#			eval cache_and_display \$filetype \$resulttype \$filename fas_env conf $args
		#		} else {
		#			fas_debug "fas_display.tcl - depedency met returning content of cache_and_display for $filetype $resulttype $filename fas_env conf $args"
		#			return "[eval cache_and_display \$filetype \$resulttype \$filename fas_env conf $args]"
		#		}
			#}
		#} else {
			# Nothing was cached till now
			# To be displayed and cached
			fas_debug "fas_display.tcl - display_file $filetype $filename $args - nothing cached till now -$output_filename is not readable"
			if { !$NODISPLAY } {
				#eval cache_and_display \$filetype \$resulttype \$filename fas_env conf $args
				if 1 [concat [list cache_and_display $filetype $resulttype $filename fas_env conf] $args]
			} else {
				fas_debug "fas_display.tcl - no dependency returning content of cache_and_display $filetype $resulttype $filename fas_env conf $args"
				return "[eval cache_and_display \$filetype \$resulttype \$filename fas_env conf $args]"
			}
		#}
	} else {
		fas_debug "fas_display.tcl - display_file $filetype $filename $args : resulttype -> {}"

		# The file should be directly displayed.
		# This is typically the case of an html file.
		# So the interpretation of the file must be done.
		if { !$NODISPLAY } {
			${filetype}::display fas_env $filename
		} else {
			# fas_debug "fas_display.tcl::display_file returning a content
			# -> ${filetype}::content fas_env $filename ->[${filetype}::content fas_env $filename]"
			set tmp_result [${filetype}::content fas_env $filename]
			# fas_debug "fas_display.tcl::display_file returning a content -+${tmp_result}+-"
			return $tmp_result
		}
	}
		
}

# Name : display_content
# The main procedure for displaying ANY content type.
# In other words, it changes a file into html, gif, jpeg or pdf.
# It sends back the content displayed
proc display_content { filetype content current_env current_conf args} {
	fas_debug "fas_display.tcl - display_content filetype -> $filetype args -> $args"
	#fas_debug "fas_display.tcl::display_content filetype -> $filetype args -> $args \n------------content-------------------\n$content\n----------/content--------------------------------\n"
	upvar $current_env fas_env
	upvar $current_conf conf

	# Please do not display the final result
	set NODISPLAY 0

	set state parse_args
	foreach arg $args {
		switch -exact -- $state {
			parse_args {
				switch -glob -- $arg {
					-nod* {
						#nodisplay
						set NODISPLAY 1
					}
				}
			}
		}
	}
	
	fas_debug "fas_display.tcl - display_content : NODISPLAY -> $NODISPLAY"
	# filename must be transformed from filetype into conf(newtype.filetype)
	#set resulttype $conf(newtype.$filetype)
	global ROOT
	set root_menu_dir $ROOT
	set root_menu_dir [add_root [fas_name_and_dir::get_root_dir]]
	#if { [info exists fas_env(root_directory)] } {
	#	set root_menu_dir [add_root $fas_env(root_directory)]
	#} else {
	#	fas_display_error "[translate "No key"] root_directory [translate "was defined in the current file environment variables. Please define it."]"  env
	#}
	#if { [info exists env(tmpl.menuroot) ] } {
	#	set root_menu_dir [file join $root_menu_dir $fas_env(tmpl.menuroot)]
	#} 

	if { ![catch { set resulttype [${filetype}::new_type fas_env $root_menu_dir]} ] } {
		# the file must be processed again
		fas_debug "fas_display.tcl - display_content ${filetype}::content2${resulttype} -> [llength [info commands ${filetype}::content2${resulttype}]] "
		if { [llength [info commands ${filetype}::content2${resulttype}]] > 0 } {
			fas_debug "fas_display.tcl - display_content entering ${filetype}::content2${resulttype}"
			set content [${filetype}::content2${resulttype} fas_env $content]
			set content [eval display_content \$resulttype \$content fas_env conf $args]
		} else {
			# I directly display
			if { !$NODISPLAY } {
				${filetype}::content_display fas_env $content
			}
		}
	} else {
		# I display the file
		if { !$NODISPLAY } {
			${filetype}::content_display fas_env $content
		} 
	}
	return $content
}

# Cache and display the file.
proc cache_and_display { filetype resulttype filename current_env current_conf args } {
	fas_debug "fas_display.tcl - cache_and_display - $filetype current_env current_conf $args"
	upvar $current_env fas_env
	upvar $current_conf conf

	# Possible content to display, nothing in the file
	# Please do not display the final result
	set NODISPLAY 0

	set state parse_args
	foreach arg $args {
		switch -exact -- $state {
			parse_args {
				switch -glob -- $arg {
					-nod* {
						#nodisplay
						set NODISPLAY 1
					}
				}
			}
		}
	}
	
	
	# set resulttype [${filetype}::new_type fas_env $filename]
	fas_debug "fas_display.tcl - cache_and_display - filetype -> $filetype to resulttype -> $resulttype"
	if { [llength [info commands ${filetype}::2${resulttype}]] > 0 } {
		# there is a command to convert the information
		# First I determine the real filename, it may be the real filename
		# or it may be a cached file. I think that yyy::2xxx should not 
		# bother about that.

		# Initializing the dependencies
		fas_depend::init_dependencies 
		main_log "Calling ${filetype}::2${resulttype} on [rm_root $filename]"
		set final_content [${filetype}::2${resulttype} fas_env $filename]
		# And now I must cache the content
		cache ${resulttype} $filename fas_env $final_content
		# And also I display the result

		if { !$NODISPLAY } {
			#eval display_file \${resulttype} \$filename fas_env conf $args
			if 1 [concat [list display_file $resulttype $filename fas_env conf] $args]
		} else {
			fas_debug "fas_display.tcl::cache_and_display returning display_file $resulttype $filename fas_env conf $args"
			set tmp_result "[eval display_file \${resulttype} \$filename fas_env conf $args]"
			# fas_debug "fas_display.tcl::cache_and_display returning from display_file $resulttype $filename fas_env conf $args -+${tmp_result}+-"
			return $tmp_result
		}
	} else {
		# There is no way to convert the file
		# It must be displayed directly
		if { !$NODISPLAY } {
			${filetype}::display fas_env $filename
		} else {
			fas_debug "fas_display.tcl::cache_and_display returning ${filetype}::content fas_env $filename"
			set tmp_result "[${filetype}::content fas_env $filename]"
			# fas_debug "fas_display.tcl::cache_and_display returning -+${tmp_result}+-"
			return $tmp_result
		}
	}
}

# Name of the cached file for filetype $filetype for $filename
# We get it in replacing env(root_directory) at start of the filename
# by env(cache.$filetype) or env(cache)/$filetype if env(cache.$filetype)
# does not exist.
# example :
# filename /home/httpd/html/fas_view/any/index.txt
# env(root_directory) /home/httpd/html/fas_view/any
# env(cache.html) /home/httpd/html/fas_view/html
# => /home/httpd/html/fas_view/html/index.txt
#
# Concerning the cache name, I am going to take into account the following
# arrays :
#  * fas_session::session
#  * _cgi_uservar (except file)
#  * _cgi_cookie (except file)
# WHEN ENTERING IN THIS FUNCTION, I SUPPOSE THAT 
# fas_env(cache) OR fas_env(cache.$filetype) EXISTS
# args => if there is anything, (-n) I send back the file without taking into
# account all & & & &conf env _user_var informations
proc cache_filename { filetype filename current_fas_env args } {
	upvar $current_fas_env fas_env

	set NO_EXTENSION 0

	if { [llength $args] > 0 } {
		set NO_EXTENSION 1
	}

	catch { global fas_session::session }
	global _cgi_cookie
	global _cgi_uservar
	
	set cache_filename $filename

	set current_filename [suppress_root [fas_name_and_dir::get_root_dir] [rm_root $filename]]

	#if { [info exists fas_env(root_directory)] } {
	#	set current_filename [suppress_root $fas_env(root_directory) [rm_root $filename]]
	#} else {
	#	set current_filename $filename
	#}
	set cache_filename "[add_root [file join [fas_name_and_dir::get_cache_dir fas_env] $filetype $current_filename]]"
	#if { [info exists fas_env(cache.$filetype)] } {
	#	set cache_filename "[add_root [file join $fas_env(cache.$filetype) $current_filename]]"
	#	fas_debug "fas_display.tcl - cache_filename - using cache.$filetype and $current_filename"
	#} elseif { [info exists fas_env(cache)] } {
	#	set cache_filename "[add_root [file join $fas_env(cache) $filetype $current_filename]]"
	#	fas_debug "fas_display.tcl - cache_filename - using cache and $filetype and $current_filename"
	#} else {
	#	set cache_filename "[add_root [file join [fas_name_and_dir::get_root_dir] cache $filetype $current_filename]]"
	#}
		
	
	#if { [info exists fas_env(root_directory)] } {
	#	set cache_filename "[add_root [file join $fas_env(root_directory) cache $filetype $current_filename]]"
	#	fas_debug "fas_display.tcl - cache_filename - using root_directory / cache and $filetype and $current_filename"
	#} else {
	#	set cache_filename "[add_root $current_filename]"
	#	fas_debug "fas_display.tcl - cache_filename - WARNING STRANGE - using  $current_filename"
	#}
	if { $NO_EXTENSION } {
		return $cache_filename
	} else {
		global conf
		# Ridiculous. Either I user fas_session or cookies but not both. 
		# I take out the _cgi_cookie, I just use the fas_session::session_string
		# and not the cookie. I also add the username. 
		# Today, I just use the cookie for the session number, and not for
		# anything else. Then, I take cookie out.
		if { $conf(system.session) } {
			#set candidate_cache_filename "${cache_filename}&[fas_session::string $filetype]&[array_string _cgi_uservar]&[array_string _cgi_cookie]"
			set candidate_cache_filename "${cache_filename}&user=[fas_user::who_am_i]&[fas_session::session_string $filetype]&[array_string _cgi_uservar]"
		} else {
			fas_debug "fas_display.tcl - cache_filename - NO SESSION - using  $cache_filename"
			# But I need the filetype
			set candidate_cache_filename "${cache_filename}&user=[fas_user::who_am_i]&[array_string _cgi_uservar]"
		}
		if { [info exists conf(tclhttpd)] } {
			append candidate_cache_filename "&tclhttpd"
		}
		if { [info exists conf(tclrivet)] } {
			append candidate_cache_filename "&rivet"
		}
		# OOOPppps under unix filename can not be more than 255 caracters
		# Ideally, I should compute a md5 for the string and use it as an extension
		if { [string length $candidate_cache_filename] > 255 } {
			# trying a md5 on that
			#set candidate_cache_filename [string range $candidate_cache_filename 0 255]
			set candidate_cache_filename "${cache_filename}[::md5::md5 -hex $candidate_cache_filename]"
		}
		fas_debug "fas_display.tcl - cache_filename - $candidate_cache_filename"
		return $candidate_cache_filename
			
	}
}

	
proc cache { filetype filename current_fas_env content } {
	upvar $current_fas_env fas_env
	#fas_debug "cache $filetype $filename fas_env content \n---------\n$content\n-----------"
	# Here I just store the file when it is necessary to store it
	# parray fas_env
	# if { [info exists fas_env(cache.$filetype)] || [info exists fas_env(cache)] || [info exists fas_env(root_directory)] } {
		set cache_filename "[cache_filename $filetype $filename fas_env]"
		# Now I must test if the directory exists or not
		set cache_dirname [file dirname $cache_filename]
		if { ![file isdirectory $cache_dirname] } {
			catch { file mkdir $cache_dirname }
		}
		fas_debug "cache -> trying to write $cache_filename"
		if { ![catch {open "$cache_filename" w} fid] } {
			if { [llength [info commands ${filetype}::write_cache_file]] } {
				${filetype}::write_cache_file $fid $content
			} else {
				puts $fid $content
				close $fid
			}
			# And I write the dependencies for this file
			fas_depend::write_dependencies $cache_filename
			main_log "Caching [rm_root $cache_filename]"
		} else {
			fas_display_error "fas_display.tcl - cache - [translate "Could not cache file"] [rm_root $cache_filename]" fas_env -f $filename
		}
	#}
}

proc get_cache_file_content { filetype filename current_env } {
	# A procedure for just getting the content of a file
	# Here there are 2 cases, either it is the real file
	# or I must take the file from the html cache directory.
	upvar $current_env env
	set content ""
	# set real_filename [get_real_filename $filetype $filename env]
	if { [ catch {fas_name_and_dir::get_real_filename $filetype $filename env} real_filename] } {
		error "get_cache_file_content - Could not find $filename"
	} else {
		if { [catch {
			fas_debug "fas_display.tcl::get_cache_file_content opening $real_filename"
			set fid [open $real_filename]
			set content [read $fid]
			#fas_debug "fas_display.tcl::get_cache_file_content content ->$content<-"
			close $fid 
		} ] } {
			# there was a pb during opening
			error "get_cache_file_content - Could not get $filename content"
		} 
	} ; # no cache directory
	return $content
}

proc fas_exit { } {
	global conf
	# First I write the session !!!!!!!!!!!!!
	catch { fas_session::write_session }
	if { [info exists conf(tclhttpd)] } {
		fas_debug "fas_display::fas_exit - tclhttpd case"
		# I try :
		#global conf
		Httpd_SockClose  $conf(sock) 1
		# !!!!!!!! Bad idea it leads to
		# pages that are not correctly displayed
		#wait 1000
		error "fas_exit"
		#after 1000 error "fas_exit"
	} elseif { [info exists conf(tclrivet)] } {
		#fas_debug "fas_display::fas_exit - tclrivet case"
		abort_page
		#error "fas_exit"
	} else {
		fas_debug "fas_display::fas_exit - cgi case => exit"
		#::profiler::print
		exit
	}
}

# From the name of a file, guess the filetype of it
proc guess_filetype { filename current_conf current_env } {
	upvar $current_conf conf
	upvar $current_env fas_env

	#fas_debug "guess_filetype -> conf_array"
	#fas_debug_parray conf "guess_filetype -> conf"

	# First determining if it is or not a directory
	if { [file isdirectory $filename] } {
		set filetype dir
		# Now is it an order directory or a normal one
		if { [info exists fas_env(dir_type)] } {
			set filetype $fas_env(dir_type)
		}
	} else {
		if { [info exists fas_env(file_type)] } {
			# In some rare case, I can not rely on the
			# extension to know the filetype, I put it as
			# a parameter
			set filetype $fas_env(file_type)
		} else {
			# For each file in mimeprocs, I will have a list of extension
			# I must guess the type of the file depending of the extension
			# I use the extension section of conf to decide it
			set file_extension [string trim [file extension $filename] "."]
			set filetype $file_extension

			fas_debug "guess_filetype file_extension -> $file_extension for $filename"
			if [info exists conf(extension.${file_extension})] {
				fas_debug "guess_filetype : found extension.${file_extension} in conf"
				set filetype $conf(extension.${file_extension})
			} elseif [regexp {[0-9]+} $file_extension match] {
				fas_debug "guess_filetype : found a tiff g3 fax file"
				set filetype "tiffg3"
			} else {
				set filetype other
			}
		}
	}
	fas_debug "guess_filetype -> result : $filetype"
	return $filetype
} 
