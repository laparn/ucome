set conf(extension.tmpl) tmpl
set conf(extension.html) tmpl
set conf(extension.htm) tmpl

lappend filetype_list tmpl

namespace eval tmpl {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		upvar $current_env fas_env
		# When a tmpl is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) htmf
		# This is the default answer
		#set result html
		set result comp
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "tmpl::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}

		if { ![catch {set target [fas_get_value target -noe]}] } {
			switch -exact -- $target {
				tmpl {
					fas_debug "tmpl::new_type - error => direct display"
					# I stop here
					#error 1
					return ""
				}
				txt4index {
					set result txt4index
				}
				ori {
					set result txt
					#error 1
					return ""
				}
				rrooll -
				rool {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rool"
					set result comp
				}
				rrooll2 -
				rool2 {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rool2"
					down_stage_env fas_env "rrooll2.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rool2"
					set result comp
				}
				rrooll3 -
				rool3 {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rool3"
					down_stage_env fas_env "rrooll3.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rool3"
					set result comp
				}
			}
		}
		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "fashtml" ) && ( $new_type_option == "notmpl" ) } {
			set result htmf
		}
		
		fas_debug "tmpl::new_type -> $result "
		return $result
	}

	# List of possible types in which this file type may be converted
	proc new_type_list { } {
		return [list fashtml comp txt4index]
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
		lappend env_list [list "tmpl.view.comp" "Composite file used to integrate this file content." webmaster]
		lappend env_list [list "tmpl.notablewidth" "Suppress all table width of 100% as it poses problem in xhtml on IE." user]
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf args } {
		fas_debug "tmpl::new - _env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		eval fashtml::new fas_env fas_conf $args
	}

	proc mimetype { } {
		return "text/html"
	}

	proc ucome_doc { } {
		set content {This is html without any graphical navigation frames : no menu, no news, nothing. So if you want to include existing html files in a UCome site, just take them, drop them in a directory, and in the file_type property put "tmpl" for this file. If you add text in the menu.name and menu.order property, the file will also appear in the menu.}
		return $content
	}

	proc 2htmf { current_env args } {
		upvar $current_env fas_env

		return [eval fashtml::2htmf fas_env $args]
	}

	proc content2htmf { current_env args } {
		upvar $current_env fas_env

		return [eval fashtml::content2htmf fas_env $args]
	}

	proc 2fashtml { current_env filename } {
		upvar $current_env env
		return  [generic2fashtml env -f $filename ]
	}
	
	proc content2fashtml { current_env content } {
		upvar $current_env env
		return  [generic2fashtml env -c $content ]
	}

	proc 2comp { current_env filename } {
		upvar $current_env fas_env
		set real_filename [fas_name_and_dir::get_real_filename tmpl $filename fas_env]
		set content "[generic2fashtml fas_env -f $filename]"
		array set tmp ""
		global _cgi_uservar
		if { [info exists _cgi_uservar(message)] } {
			set tmp(content.content) "<h1>$_cgi_uservar(message)</h1>[extract_body $content]"
		} else {	
			set tmp(content.content) [extract_body $content]
		}
		return "[array get tmp]"
	}
		
	
	# Convert into html the input and return the corresponding
	# string.
	# -nocache : do not try to take or to write a cachefile
	# -c content : content to display
	# -f filename : file from which to take the content
	proc generic2fashtml { current_env args } {
		upvar $current_env fas_env
		set NOCACHE 0
		set CONTENT_TYPE ""
		set content_string ""
		set state parse_args
		foreach arg $args {
			switch -exact -- $state {
				parse_args {
					switch -glob -- $arg {
						-f* {
							#filename
							set state filename
						}
						-c* {
							#content
							set state content
						}
						-n* {
							#nocache
							set NOCACHE 1
						}
					}
				}
				filename {
					set filename $arg
					set CONTENT_TYPE "file"
					set state parse_args
				}
				content {
					set content $arg
					#set filename "$ROOT"
					#set real_filename $filename
					# filename is initialised here under
					set CONTENT_TYPE "string"
					set state parse_args
				}

			}
		}

		# What is the real filename to take the content from ?
		if { $CONTENT_TYPE == "file" } {
			set real_filename [fas_name_and_dir::get_real_filename tmpl $filename fas_env]
			# Basically, the output depends on the input file
			fas_depend::set_dependency $real_filename file

			# The output depends on some variables in the env files
			fas_depend::set_dependency $filename fas_env
			# There is a problem for OpenOffice files, for the
			# first file. I need to jump back to original file :
			# First page link jump to autocache/toto.sxi/toto.sxi.html
			# I put a special env file, to say that in this case, I must
			# display the original file toto.sxi
			if { [info exists fas_env(nodisplay.jumpto)] } {
				set jumptonoroot $fas_env(nodisplay.jumpto)
				set jumpto [add_root $jumptonoroot]
				global _cgi_uservar
				global conf
				unset _cgi_uservar
				set _cgi_uservar(action) "view"
				read_full_env $jumpto fas_env
				set filetype [guess_filetype $jumpto conf fas_env]
				fas_debug "tmpl::generic2fashtml - nodisplay.jumpto case"
				fas_debug "tmpl::generic2fashtml - display_file $filetype $jumpto fas_env conf"
				display_file $filetype $jumpto fas_env conf
				fas_exit
			}
			catch {
				set fid [open $real_filename]
				set content [read $fid]
				close $fid
			}
			# There is a problem on linbox site if we are in
			# a full xhtml design. Tables with 100% width are
			# doing an ugly html in the content area. I do
			# a simple function for trying to remove these
			# tags, if a particular property is set
			fas_debug "tmpl::generic2html - does fas_env(tmpl.notablewidth exists ?"
			if { [info exists fas_env(tmpl.notablewidth)] } {
				fas_debug "yes - doing the substitution"
				# remove all table width from the content
				regsub -all {(< *[tT][aA][Bb][Ll][Ee][^>]+)[Ww][Ii][Dd][Tt][Hh] *="*100%"*([^>]*>)} $content {\1\2} content
			}
		}
		return $content
	}

	proc 2txt4index { current_env filename } {
		upvar $current_env fas_env
		return [fashtml::2txt4index fas_env $filename]
	}

	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		txt::2edit_form fas_env $filename
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		txt::2edit fas_env $filename
	}
		
	
	proc get_title { filename } {
		# a pure copy of html one
		set title ""
		if { ![catch {open $filename} fid] } {
			set file [read $fid]
			close $fid
			regexp {< *[Tt][Ii][Tt][Ll][Ee] *>(.*?)< */[Tt][Ii][Tt][Ll][Ee] *>} $file match title
		}
		return $title
	}

	# begin modif Xav
	proc mimetype { } {
		return "text/html"
	}
	# end modif Xav

	proc content_display { current_env content } {
		return "[not_binary::content_display tmpl $content]"
	}

	proc display { current_env filename } {
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename tmpl]"
	}

	proc content { current_env filename } {
		upvar $current_env fas_env
		return "[not_binary::content fas_env $filename tmpl]"
	}
}
