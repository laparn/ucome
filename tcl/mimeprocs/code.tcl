# extension for txt
set conf(extension.c) code
set conf(extension.f) code
set conf(extension.f90) code
set conf(extension.f77) code
set conf(extension.f95) code
set conf(extension.py) code
set conf(extension.h) code
set conf(extension.cpp) code
set conf(extension.tcl) code
set conf(extension.cgi) code
set conf(extension.tcl) code
set conf(extension.template) code
# ... add all the extensions that you want that
# are handled by vim

lappend filetype_list code

# And now all procedures for code
namespace eval code {
	# What command to use to translate the txt in txt2ml
	# The -re option allows to convert relative links in absolute one
	# Finally, I put this function in htmf, then it is not useful in
	# the command line here.
	# For debian : /usr/bin/vim
	# For Mandriva : /bin/vim
	set local_conf(vim) "/bin/vim"

	set ucome_doc {This filetype is used for displaying all source code of programs. You just need to have the extension defined (add a "set conf(extension.xxx) code" at start of tcl/mimeprocs/code.tcl . vim is used for the syntax highlighting.

You may have to change the path of vim in local_conf(vim) in the file code.tcl to match your installation.
	
Any syntax highlighting program may be used, but you will have to tweak the code. Just change the line 
================================
catch { exec $local_conf(vim) -s ${FAS_PROG_ROOT}/highlight.vim ${real_filename}  error }
================================
by whatever you wish. Beware, it is supposed that the result is in ${real_filename}.html as it is done here.  }

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		upvar $current_env fas_env
		# When a code is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result comp
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "code::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		if { ![catch {set target [fas_get_value target -noe]}] } {
			# we are in the standard case nothing to do
			switch -exact -- $target {
				txt {
					# I throw an error I am at the end
					set result txt
					#error 1
					return ""
				}
				pdf  {
					down_stage_env fas_env "pdf.cgi_uservar." 
					set result comp
					# No need to write it, but it is more clear so
				}
				nomenu {
					set result fashtml
				}
				ori {
					set result txt
					#error 1
					return ""
				}
				# begin modif Xav
				rrooll -
				rool {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rool"
					set result comp
				}
				# end modif Xav
			}
		}
		fas_debug "code::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list comp fashtml txt pdf txt4index]
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
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf args } {
		fas_debug "code::new - _env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		eval fashtml::new fas_env fas_conf $args
	}

	proc mimetype { } {
		return "text/plain"
	}



	# This procedure will translate a txt into a tmpl
	# This is very arbitrary, as it may also be seen as pure 
	# html. It is just conf(newtype.txt) that will say
	# how it will be changed (in which cache directory it will be
	# written).
	proc 2tmpl { current_env args } {
		fas_debug "txt::2tmpl - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2tmpl { current_env args } {
		fas_debug "txt::content2tmpl - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
	}
	
	proc 2comp { current_env args } {
		fas_debug "txt::2comp - $args"
		upvar $current_env fas_env
		# begin modif Xav
		#set tmp(content.content) "[extract_body [eval 2fashtml fas_env $args ]]"
		if { [info exists ::_cgi_uservar(message)] } {
			set tmp(content.content) "<h1>$::_cgi_uservar(message)</h1>[extract_body [eval 2fashtml fas_env $args ]]"
		} else {	
			set tmp(content.content) "[extract_body [eval 2fashtml fas_env $args ]]"
		}
		# end modif Xav
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "txt::content2comp - $args"
		upvar $current_env env
		set tmp(content.content) "[extract_body [eval content2fashtml env $args ]]"
		return "[array get tmp]"
	}
	
	# This procedure will translate a txt into html 

	# The dependencies are the following :
	#  - eventually $env(perso.tcl), $env(style)
	proc 2fashtml { current_env filename args } {
		upvar $current_env env
		variable local_conf
		global FAS_PROG_ROOT

		set real_filename [fas_name_and_dir::get_real_filename code $filename env]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		# The next flag indicates if the output file needs
		# or does not need to be created.
		# I will store the result in /tmp/filename.html
		# Then I load it and send it back
		catch { exec $local_conf(vim) -s ${FAS_PROG_ROOT}/highlight.vim $real_filename } error 
		set filename_end [file tail $real_filename]
		set potential_htmlfile [file join /tmp "${filename_end}.html"]

		if { [catch { 
				set fid [open $potential_htmlfile]
				set content [read $fid]
				close $fid
			} ] } {
			return "<html><body>Problem while converting the file [rm_root $real_filename] and reading result_file $potential_htmlfile.<br>$error<br>$local_conf(vim) -s ${FAS_PROG_ROOT}/highlight.vim $real_filename</body></html>"
		}
		catch { file delete -force $potential_htmlfile }
		return $content
	}

	# This procedure will translate a string in code format into html thanks to vim
	# The args arguments, will be sent as is to the txt2ml command
	proc content2fashtml { current_env content args} {
		upvar $current_env fas_env
		global conf
		

		# I must create a random name and store the file there. 
		# I use the same algo than for session. And store in session dir

		set session_name "[clock seconds]_[pid]_[expr int(100000000 * rand())].code"
		# I test if it previously exists or not
		set session_file_name [add_root [file join [get_cache_dir] $session_name]]
		while { [file readable  $session_file_name ] } {
			set session_name "[clock seconds]_[pid]_[expr int(10000000000 * rand())].code"
			set session_file_name [add_root [file join [get_cache_dir] $session_name]]
		}
		
		set fid [open $session_file_name w]
		puts $fid $content
		close $fid
		
		# Now converting
		if{ [llength $args] > 0 } {
			set result [eval 2fashtml fas_env $session_file_name $args]
		} else {
			set result [2fashtml fas_env $session_file_name]
		}

		# and returning the result
		file delete $session_file_name
		return $result
	}

	proc get_title { filename } {
		fas_debug "code::get_title entering"
		set title [::not_binary::get_title $filename]
		fas_debug "code::get_title found ->$title<-"
		return $title
	}
	
	
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env

		set result [txt::2edit_form fas_env $filename]
		return $result
	}
	
	proc 2edit { current_env filename } {
		upvar $current_env fas_env

		set result [txt::2edit fas_env $filename]
		fas_exit
	}
		
	proc content_display { current_env content } {
		return "[not_binary::content_display txt $content]"
	}
		
	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename txt]"
	}
	proc content { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::content fas_env $filename tmpl]"
	
	}

	proc 2txt4index { current_env filename } {
		upvar $current_env fas_env
		set real_filename [fas_name_and_dir::get_real_filename code $filename env]
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file
		return "[not_binary::content fas_env $filename txt]"
	}
}
