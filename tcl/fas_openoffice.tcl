set ::OPENOFFICE_PROCEDURES {
	proc new_type { current_env filename } {
		variable local_conf
		set result comp
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "$local_conf(ootype)::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		if { ![catch {set target [fas_get_value target -noe] } ] } {
			switch -exact -- $target {
				pdf  {
					# So I must take pdf.cgi_uservar informations
					fas_debug_parray fas_env "$local_conf(ootype)::new_type fas_env before down_stage_env"
					down_stage_env fas_env "pdf.cgi_uservar." 
					fas_debug_parray fas_env "$local_conf(ootype)::new_type fas_env after down_stage_env"
					set result pdf
					# No need to write it, but it is more clear so
				}
				htmf  {
					set result comp
					# No need to write it, but it is more clear so
				}
				fashtml {
					set result comp
				}
				nomenu {
					set result fashtml
				}
				txt4index {
					set result txt4index
				}
				ori {
					#error 1
					return ""
				}
			}
		}
		fas_debug "$local_conf(ootype)::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		variable local_conf
		return [list comp fashtml txt tmpl $local_conf(ootype)]
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
		lappend env_list [list "always_autocache" "Always take an autocache file, even if the file is younger than the autocache." user]
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	#proc may_create { } {
	#	return 1
	#}
	proc mimetype { } {
		# WARNING I PUT SOMETHING CERTAINLY WRONG TO BE CHANGED
		return "openoffice/application"
	}



	# This procedure will translate an openoffice  into a comp
	proc 2comp { current_env args } {
		fas_debug "openoffice::2comp - $args"
		upvar $current_env fas_env

		array set tmp ""
		global _cgi_uservar
		if { [info exists _cgi_uservar(message)] } {
			set tmp(content.content) "<h1>$_cgi_uservar(message)</h1>[eval 2fashtml fas_env $args ]"
		} else {	
			set tmp(content.content) "[eval 2fashtml fas_env $args ]"
		}
		return "[array get tmp]"
	}
	
	proc 2fashtml { current_env filename args } {
		upvar $current_env fas_env
		variable local_conf

		set real_filename [fas_name_and_dir::get_real_filename $local_conf(ootype) $filename env]
		fas_depend::set_dependency $real_filename file
		# NORMALLY I SHOULD HAVE A FONCTION FOR CHANGING AN OPENOFFICE
		# DOCUMENT INTO HTML. IT IS POSSIBLE TO DO THANKS TO THE SDK
		# NOW AVAILABLE FOR OPENOFFICE. HOWEVER, IT IS NOT DONE, AND
		# I DO NOT KNOW WHERE TO GET IT => THE USER SHOULD PUT IN THE
		# SAME DIRECTORY A FILE WITH THE SAME NAME WITH .html AT THE END
		# toto.sxc.html FOR EXAMPLE. I WILL USE THIS FILE FOR DOING THE JOB

		# This function will take a sxw and convert it into an autocache file
		# Do I have an autocache ? Do I use it ?
		set autocache_filename [get_autocache_filename $real_filename]
		fas_depend::set_dependency $autocache_filename

		# Does it exist ?
		set AUTOCACHE_EXIST 0
		if { [file readable $autocache_filename] } {
			if { [info exists fas_env(always_autocache)] } {
				if $fas_env(always_autocache) {
					set AUTOCACHE_EXIST 1
				}
			}
			if { [file mtime $autocache_filename] > [file mtime $real_filename] } {
				set AUTOCACHE_EXIST 1
			}
		}

		if { !$AUTOCACHE_EXIST } {
			# If autocache is not good, I work it out again
			# Trying oo
			# Does the directory exists 
			set autocache_dir [file dirname $autocache_filename]
			if { ![file readable $autocache_dir] } {
				if { [catch {file mkdir $autocache_dir; file attributes  $autocache_dir -permissions "ugo+rwx"} error] } {
					set content "<h1>$local_conf(ootype)::2fashtml - [translate "could not create autocache directory"] [rm_root $autocache_dir]</h1><pre>$error</pre>"
					return $content
				}
			}
					
			variable local_conf
			# All filenames must be absolute
			set command "$local_conf(convert_html) \"$real_filename\" \"$autocache_filename\""

			fas_debug "$local_conf(ootype)::2fashtml - command => $command"
			if { [catch {eval exec $command} error] } {
				# An error occured
				return "<h1>$local_conf(ootype)::2fashtml - [translate "Problem while converting an OpenOffice.org file into html - maybe OpenOffice.org is not set up ?"]</h1><p>$real_filename -> $autocache_filename</p><pre>$error</pre>"
			} else {
				# I need to clean the html.
				if { [ catch {open $autocache_filename} fid ] } {
					# I ignore the error
				} else {
					set html_content [read $fid]
					close $fid
					# Now cleaning
					# First thing to do add autocache at start of all
					# img src tag
					set html_result [process_html $html_content {<[Ii][Mm][Gg][^>]+?>} {(.*[Ss][Rr][Cc]=["'])([^ >]+)(["'].*)}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *position:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *top:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *bottom:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *width:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *height:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Ss][Pp][Aa][Nn][^>]+?>} { *float:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Ss][Pp][Aa][Nn][^>]+?>} { *width:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Ss][Pp][Aa][Nn][^>]+?>} { *height:[^;]+;} {}]
					#set html_result $html_content
					# And storing the result
					if { ![ catch {open $autocache_filename w} fid ] } {
						puts $fid $html_result
						close $fid
					} else {
						return "$local_conf(ootype)::2fashtml - [translate "Could not open autocache file for writing : "] [file tail $autocache_filename]<BR><pre>$fid</pre>"
					}
				}
			}
			# else it is OK, I can extract auto_cache now
		}


		if { [catch {set content [get_autocache_content $real_filename]} error ] } {
			return "$local_conf(ootype)::2fashtml - [translate "Automatic conversion is not yet handled, please put a file named as "] [file tail $autocache_filename] [translate "in the current directory. Thanks."]<BR>$error"
		}

		# Now extracting the body
		return [extract_body $content]
	}

	# Detect on after the orther the $tag and process the url described
	# by the $url regular expression to change it into an "autocache" one
	proc process_html { content tag url } {
		set begin 0
		set result ""
		while { $begin != [string length $content] } {
			regexp -indices -start $begin ($tag) $content match indices
			if { [info exists indices] } {
				# a match has been found in the rest of the string
				set begin_tag [lindex $indices 0]
				set end_tag [lindex $indices 1]
				# we add to result what has not been matched
				set result "$result[string range $content $begin [expr $begin_tag - 1] ]"
				# we process the portion of the original string
				# thas has been matched, and add it to the result
				set result "$result[to_autocache_url [string range $content $begin_tag $end_tag] $url]"
				# the next regexp will now start after end_tag
				set begin [expr $end_tag + 1]
				unset begin_tag
				unset end_tag
				unset indices
			} else {
				# no match has been found, so we have nothing more to do
				# we add to the result the rest of the original string
				set result "$result[string range $content $begin [string length $content]]"
				set begin [string length $content]
			}
		}
		# we put in content the result of the process
		set content $result
	}

	# A single procedure to change the url to match autocache ones
	# Strongly inspired from to_right_url in fashtml.tcl
	proc to_autocache_url { str re } {
		set result ""

		if {[regexp $re $str match start url end]} {
			if { ![regexp ":" $url match] && ![regexp {[?]} $url match] && [string range $url 0 0] != "/" } {
				# it is a relative link I must add auto_cache before
				set result "autocache/${url}"
			} else {
				# It is an absolute link
				set result "$url"
			}
			set result "$start$result$end"
			# fas_debug "$result avec url = $url"
		} else {
			# no url found in the matched tag
			# we return str without changes
			set result "$str"
		}
		return $result
	}

	# Detect one after the orther the $tag and process the url described
	# by the $url regular expression to change it into what is described
	# in re which is also a regular expression
	proc clean_html { content tag to_be_cleaned suppress } {
		set begin 0
		set result ""
		while { $begin != [string length $content] } {
			regexp -indices -start $begin ($tag) $content match indices
			if { [info exists indices] } {
				# a match has been found in the rest of the string
				set begin_tag [lindex $indices 0]
				set end_tag [lindex $indices 1]
				# we add to result what has not been matched
				set result "$result[string range $content $begin [expr $begin_tag - 1] ]"
				# we process the portion of the original string
				# thas has been matched, and add it to the result
				set result "$result[clean_string [string range $content $begin_tag $end_tag] $to_be_cleaned $suppress]"
				# the next regexp will now start after end_tag
				set begin [expr $end_tag + 1]
				unset begin_tag
				unset end_tag
				unset indices
			} else {
				# no match has been found, so we have nothing more to do
				# we add to the result the rest of the original string
				set result "$result[string range $content $begin [string length $content]]"
				set begin [string length $content]
			}
		}
		# we put in content the result of the process
		set content $result
	}
	proc clean_string { content to_be_cleaned suppress } {
		set result $content

		regsub -all $to_be_cleaned $content $suppress result

		return $result
	}
	proc 2pdf { current_env filename args } {
		upvar $current_env fas_env
		variable local_conf

		set real_filename [fas_name_and_dir::get_real_filename $local_conf(ootype) $filename env]
		fas_depend::set_dependency $real_filename file
		# NORMALLY I SHOULD HAVE A FONCTION FOR CHANGING AN OPENOFFICE
		# DOCUMENT INTO HTML. IT IS POSSIBLE TO DO THANKS TO THE SDK
		# NOW AVAILABLE FOR OPENOFFICE. HOWEVER, IT IS NOT DONE, AND
		# I DO NOT KNOW WHERE TO GET IT => THE USER SHOULD PUT IN THE
		# SAME DIRECTORY A FILE WITH THE SAME NAME WITH .html AT THE END
		# toto.sxc.html FOR EXAMPLE. I WILL USE THIS FILE FOR DOING THE JOB

		# This function will take a sxw and convert it into an autocache file
		# Do I have an autocache ? Do I use it ?
		set autocache_filename [get_autocache_filename $real_filename pdf]
		fas_depend::set_dependency $autocache_filename

		# Does it exist ?
		set AUTOCACHE_EXIST 0
		if { [file readable $autocache_filename] } {
			if { [info exists fas_env(always_autocache)] } {
				if $fas_env(always_autocache) {
					set AUTOCACHE_EXIST 1
				}
			}
			if { [file mtime $autocache_filename] > [file mtime $real_filename] } {
				set AUTOCACHE_EXIST 1
			}
		}

		if { !$AUTOCACHE_EXIST } {
			# Does the directory exists 
			set autocache_dir [file dirname $autocache_filename]
			if { ![file readable $autocache_dir] } {
				if { [catch {file mkdir $autocache_dir} error] } {
					set content "<h1>$local_conf(ootype)::2pdf - [translate "could not create autocache directory"] [rm_root $autocache_dir]</h1><pre>$error</pre>"
					return $content
				}
			}
			# If autocache is not good, I work it out again
			# Trying oo
			variable local_conf
			# All filenames must be absolute
			set command "$local_conf(convert_pdf) \"$real_filename\" \"$autocache_filename\""

			fas_debug "$local_conf(ootype)::2pdf - command => $command"
			if { [catch {eval exec $command} error] } {
				# An error occured
				return "<h1>$local_conf(ootype)::2pdf - [translate "Problem while converting an OpenOffice.org file into pdf - maybe OpenOffice.org is not set up ?"]</h1><p>$real_filename -> $autocache_filename</p><pre>$error</pre>"
			}
			# else it is OK, I can extract auto_cache now
		}


		if { [catch {set content [get_autocache_content $real_filename pdf]} error ] } {
			return "$local_conf(ootype)::2pdf - [translate "Automatic conversion is not yet handled, please put a file named as "] [file tail $autocache_filename] [translate "in the current directory. Thanks."]<BR>$error"
		}

		# Now extracting the body
		return "$content"
	}

	proc 2txt4index { current_env filename args } {
		upvar $current_env fas_env
		variable local_conf

		set real_filename [fas_name_and_dir::get_real_filename $local_conf(ootype) $filename env]
		fas_depend::set_dependency $real_filename file
		# NORMALLY I SHOULD HAVE A FONCTION FOR CHANGING AN OPENOFFICE
		# DOCUMENT INTO HTML. IT IS POSSIBLE TO DO THANKS TO THE SDK
		# NOW AVAILABLE FOR OPENOFFICE. HOWEVER, IT IS NOT DONE, AND
		# I DO NOT KNOW WHERE TO GET IT => THE USER SHOULD PUT IN THE
		# SAME DIRECTORY A FILE WITH THE SAME NAME WITH .html AT THE END
		# toto.sxc.html FOR EXAMPLE. I WILL USE THIS FILE FOR DOING THE JOB

		# This function will take a sxw and convert it into an autocache file
		# Do I have an autocache ? Do I use it ?
		set autocache_filename [get_autocache_filename $real_filename txt]
		fas_depend::set_dependency $autocache_filename

		# Does it exist ?
		set AUTOCACHE_EXIST 0
		if { [file readable $autocache_filename] } {
			if { [info exists fas_env(always_autocache)] } {
				if $fas_env(always_autocache) {
					set AUTOCACHE_EXIST 1
				}
			}
			if { [file mtime $autocache_filename] > [file mtime $real_filename] } {
				set AUTOCACHE_EXIST 1
			}
		}

		if { !$AUTOCACHE_EXIST } {
			# Does the directory exists 
			set autocache_dir [file dirname $autocache_filename]
			if { ![file readable $autocache_dir] } {
				if { [catch {file mkdir $autocache_dir} error] } {
					set content "<h1>$local_conf(ootype)::2txt4index - [translate "could not create autocache directory"] [rm_root $autocache_dir]</h1><pre>$error</pre>"
					return $content
				}
			}
			# If autocache is not good, I work it out again
			# Trying oo
			variable local_conf
			# All filenames must be absolute
			set command "$local_conf(convert_txt) \"$real_filename\" \"$autocache_filename\""

			fas_debug "$local_conf(ootype)::2txt4index - command => $command"
			if { [catch {eval exec $command} error] } {
				# An error occured
				return "<h1>$local_conf(ootype)::2txt4index - [translate "Problem while converting an OpenOffice.org file into txt - maybe OpenOffice.org is not set up ?"]</h1><p>$real_filename -> $autocache_filename</p><pre>$error</pre>"
			}
			# else it is OK, I can extract auto_cache now
		}


		if { [catch {set content [get_autocache_content $real_filename txt]} error ] } {
			return "$local_conf(ootype)::2pdf - [translate "Automatic conversion is not yet handled, please put a file named as "] [file tail $autocache_filename] [translate "in the current directory. Thanks."]<BR>$error"
		}

		# Now extracting the body
		return "$content"
	}

	proc get_title { filename } {
		fas_debug "openoffice::get_title entering"
		# The title is the title entry of the file
		set real_filename [fas_name_and_dir::get_real_filename txt $filename env]
		set title ""
		set html_autocache_file [get_autocache_filename $real_filename]
		if { [file readable ${html_autocache_file}] } {
			set title [fashtml::get_title $html_autocache_file]
		} else {
			set title "[translate "OpenOffice file"]"
		}
		fas_debug "openoffice::get_title found ->$title<-"
		return $title
	}
	
	
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env

		# I must be the edit form of the corresponding comp
		# but with a todo form controller
		# How can I do that ?
		return [translate "Not yet implemented"]
	}
	
	proc 2edit { current_env filename } {
		upvar $current_env fas_env

		return [2edit_form fas_env $filename]
	}
		
	proc content_display { current_env content } {
		_cgi_http_head_implicit
		puts "$content"
	}
		
	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		binary::display openoffice openoffice/application $filename env
	}

	proc 2txt4index { current_env filename } {
		upvar $current_env fas_env
		set real_filename [fas_name_and_dir::get_real_filename txt $filename env]
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		set html_autocache_file [get_autocache_filename $real_filename]
		if { [file readable ${html_autocache_file}] } {
			fas_depend::set_dependency $html_autocache_file
			return "[tmpl::2txt4index fas_env $html_autocache_file]"
		} else {
			return "[translate "Not yet implemented"]"
		}
	}
}
