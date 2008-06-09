# extension for txt
set ::conf(extension.txt) txt

lappend filetype_list txt

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval txt {
	# What command to use to translate the txt in txt2ml
	# The -re option allows to convert relative links in absolute one
	# Finally, I put this function in htmf, then it is not useful in
	# the command line here.
	global ::FAS_PROG_ROOT
	set local_conf(txt.txt2ml) "${::FAS_PROG_ROOT}/utils/txt2mlsp "

	global ::DEBUG_PROCEDURES
	eval $::DEBUG_PROCEDURES

	global ::STANDARD_PROCEDURES
	eval $::STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		fas_fastdebug {txt::new_type $filename}

		upvar $current_env fas_env
		# When a txt is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result comp
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "txt::new_type - action -> $action , action::done -> [set ${action}::done]"
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
					#error 1
					return ""
				}
				pdf  {
					# So I must take pdf.cgi_uservar informations
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env"
					down_stage_env fas_env "pdf.cgi_uservar." 
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env"
					set result comp
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
					set result txt
					#error 1
					return ""
				}
				rrooll -
				rool {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rool"
					unset ::_cgi_uservar(target)
					set result comp
				}
				rrooll1 -
				rool1 {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rrooll1"
					down_stage_env fas_env "rrooll1.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rrooll1"
					unset ::_cgi_uservar(target)
					set result comp
				}
				rrooll2 -
				rool2 {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rrooll2"
					down_stage_env fas_env "rrooll2.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rrooll2"
					unset ::_cgi_uservar(target)
					set result comp
				}
				rrooll3 -
				rool3 {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rrooll3"
					down_stage_env fas_env "rrooll3.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rrooll3"
					unset ::_cgi_uservar(target)
					set result comp
				}
			}
		}
		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "tmpl" ) && ( $new_type_option == "notmpl" ) } {
			set result fashtml
		}
		fas_debug "txt::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list comp fashtml txt pdf tmpl txt4index]
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
		lappend env_list [list "txt.perso_tcl" "Tcl file including the html code associated with each \"tag\" of txt and used when transforming the texte file in html." user]
		lappend env_list [list "txt.style" "File with a css style sheet used in html files obtained after a text transformation." user]
		lappend env_list [list "txt.ginclude_dir" "Directory from which ginclude files are taken." user]
		#lappend env_list [list "session_dir" [list en "Directory with session variables files"] [list fr "Réoertoire contenant les fichiers des variables de session"]]
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf args } {
		fas_debug "txt::new - _env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		eval fashtml::new fas_env fas_conf $args
	}

	proc mimetype { } {
		return "text/plain"
	}

	proc ucome_doc { } {
		set content { This is in fact txt2mlsp format. Please refer to the manual concerning txt2ml. It means that it is converted in html in trying to produce a pleasing result. Just write files as you would like to see them on output.

Please refer to 'the tutorial'=fas:/any/doc/tutoriel_txt2ml.txt and also to a 'summary of the whole syntax'=fas:/any/doc/recap_txt2ml.txt .  

There are 2 properties allowing to choose :
 * the file in which the html elements used for the list elements, h1, h2, ...., tables, paragraphs, ... are taken (txt.perso_tcl)
 * the css style file for the html (txt.file) }
 		return $content
	}

	# This procedure will translate a txt into a tmpl
	# This is very arbitrary, as it may also be seen as pure 
	# html. It is just conf(newtype.txt) that will say
	# how it will be changed (in which cache directory it will be
	# written).
	proc 2tmpl { current_env args } {
		fas_debug "txt::2tmpl - $args"
		upvar $current_env fas_env
		return "[eval 2fashtml fas_env $args ]"
	}
	
	proc content2tmpl { current_env args } {
		fas_debug "txt::content2tmpl - $args"
		upvar $current_env fas_env
		return "[eval content2fashtml fas_env $args ]"
	}
	
	proc 2comp { current_env args } {
		fas_debug "txt::2comp - $args"
		upvar $current_env fas_env
		global ::_cgi_uservar
		if { [info exists ::_cgi_uservar(message)] } {
			set tmp(content.content) "<h1>$::_cgi_uservar(message)</h1>[extract_body [eval 2fashtml fas_env $args ]]"
		} else {	
			set tmp(content.content) "[extract_body [eval 2fashtml fas_env $args ]]"
		}
		return "[array get tmp]"
	}

	proc content2comp { current_env args } {
		fas_debug "txt::content2comp - $args"
		upvar $current_env fas_env
		return "[eval content2fashtml fas_env $args ]"
		#return ""
	}
	
	# This procedure will translate a txt into html 

	# The dependencies are the following :
	#  - eventually $env(perso.tcl), $env(style)
	proc 2fashtml { current_env filename args } {
		fas_debug "txt::2fashtml - $args"
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename txt $filename fas_env]

		# I need the following informations
		# perso and style files, 
		# cachetmpl directory

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		# The next flag indicates if the output file needs
		# or does not need to be created.
		if { [llength $args] > 0 } {
			set end_command " $args"
		} else {
			set end_command ""
		}
		if { [info exists fas_env(txt.perso_tcl)] } {
			append end_command " -p [add_root $fas_env(txt.perso_tcl)] "
			fas_depend::set_dependency [add_root $fas_env(txt.perso_tcl)] file
		}
		if { [info exists fas_env(txt.style)] } {
			append end_command " -css [add_root $fas_env(txt.style)] "
			fas_depend::set_dependency [add_root $fas_env(txt.style)] file
		}
		if { [info exists fas_env(txt.ginclude_dir)] } {
			append end_command " -gi [add_root $fas_env(txt.ginclude_dir)] "
			fas_depend::set_dependency [add_root $fas_env(txt.ginclude_dir)] file
		}

		# And now starting txt2ml
		variable local_conf
		fas_debug "txt::2fashtml :|$local_conf(txt.txt2ml) $end_command -f $real_filename -o" 
		set fid [eval open \"|$local_conf(txt.txt2ml) $end_command -f $real_filename -o\"]
		set content ""
		if { [catch { set content [read $fid]} error] } {
			fas_display_error "txt::2fashtml - [translate "problem while processing"] $real_filename<br>$error" -file $filename 
		}
		close $fid
		#fas_debug "txt::2fashtml content => $content" 
		return $content
	}

	# This procedure will translate a string in txt2ml format into html 
	# The args arguments, will be sent as is to the txt2ml command
	proc content2fashtml { current_env content args} {
		upvar $current_env fas_env
		global ::conf
		

		# I must create a random name and store the file there. 
		# I use the same algo than for session. And store in session dir

		set session_name "[clock seconds]_[pid]_[expr int(100000000 * rand())].txt"
		# I test if it previously exists or not
		#set session_file_name [add_root [file join $fas_env(session_dir) $session_name]]
		set session_file_name [add_root [file join [fas_name_and_dir::get_session_dir] $session_name]]
		while { [file readable  $session_file_name ] } {
			set session_name "[clock seconds]_[pid]_[expr int(10000000000 * rand())].txt"
			#set session_file_name [add_root [file join $fas_env(session_dir) $session_name]]
			set session_file_name [add_root [file join [fas_name_and_dir::get_session_dir] $session_name]]
		}
		
		set fid [open $session_file_name w]
		puts $fid $content
		close $fid
		
		# Now converting
		if { [llength $args] > 0 } {
			set result [eval 2fashtml fas_env $session_file_name $args]
		} else {
			set result [2fashtml fas_env $session_file_name]
		}

		# and deleting the temporary file
		file delete $session_file_name

		# and returning the result
		return $result
	}

        # JV, 23072004
	proc 2title { current_env filename } {
	        upvar $current_env fas_env
	        fas_debug "[get_title $filename]"
	        if { [info exists fas_env(title.title)] } {
			set title "$fas_env(title.title)"
		} else {
		
		        fas_debug "txt::get_title entering"
		        # The title is the first line of the file
			set title ""
			if { ![catch {open $filename} fid] } {
				set title [gets $fid]
				regsub -all "\&" $title "\&amp;" title
				close $fid
			}
			fas_debug "txt::get_title found ->$title<-"
		}
		
		regsub -all {\&} $title {\&amp;} title
		return $title
	}

	proc get_title { filename } {
		return [::not_binary::get_title $filename]
	}
	
	
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		# ?????????? set edit_form::done 1
		# What I must do, is load a file,
		# Load and prepare a template
		# And send it back
		fas_depend::set_dependency $filename file

		# loading the file
		if { 
			[ catch {
				set fid [open $filename]
				set content [read $fid]
				close $fid
			} ]
		} {
			fas_display_error "xxx::2edit_form - [translate "Could not load "] [rm_root $filename]" fas_env
		}

		# Getting the template
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env edit_form.txt.template] } errStr] } {
			fas_display_error "xxx:2edit_form - [translate "Please define env variables"] edit_form.txt.template<br>${errStr}" fas_env
		}

		fas_depend::set_dependency $template_name file

		if { [catch { atemt::read_file_template_or_cache "EDIT_TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "xxx:2edit_form - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}
		# Preparing the variables
		atemt::atemt_set TITLE "[translate "Edit form for"] [rm_root $filename]"
		set icons_url [fas_name_and_dir::get_icons_dir]
		set export_filename [rm_root $filename]
		set dir [rm_root [file dirname $filename]]
		set from [fas_name_and_dir::get_from]
		# We substitute the variables
		set atemt::_atemt(EDIT_TEMPLATE) [atemt::atemt_subst -block FORM -block TITLE -block FILENAME EDIT_TEMPLATE]
		# Here there is filename and dir to substitute
		return [atemt::atemt_subst -end EDIT_TEMPLATE]
	}
	
	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		# I get the result of the edition
		# I save it in the file
		# Then I display the directory with some message
		# saying OK everything is fine or pb
		# If there is a pb, I try to reedit the file
		# in taking into account what was typed
		global _cgi_uservar
		set error 0
		set error_string ""
		set message ""

		if { [info exists _cgi_uservar(content)] } {
			set content $_cgi_uservar(content)
			# Trying to write filename
			if { ![file exists $filename] || [file writable $filename] } {
				if { 
					[ catch {
						set fid [open $filename w]
						puts $fid $content
						close $fid
					} errMsg ]
				} {
					incr error
					set error_string "[translate "Problem while writing "] [rm_root $filename] - ${errMsg}"
				} else {
					set message "[translate "Successful writing of "] [rm_root $filename]"
				}
			} else {
				incr error
				set error_string " [rm_root $filename] "
			}
		} else {
			incr error
			set error_string "xxx::2edit - [translate "No content to save, nothing to do."]"
		}

		#global DEBUG
		#set DEBUG 1
		# Now I really try something, calling the display of the
		# directory with a message
		# First, doing as if the message is imported variable
		if { $error } {
			set message "$error_string"
			#set ::_cgi_uservar(message) "$error_string"
		} else {
			#set message "$message"
			#set ::_cgi_uservar(message) "$message"
		}
	
		# And now asking for the display of the directory
		#set dir_name [file dirname $filename]
		#set _cgi_uservar(edit_dir) 1
		#unset _cgi_uservar(action)
		#set ::_cgi_uservar(action) "edit_form"
		set VIEW_FLAG 0
		if { [info exists _cgi_uservar(from)] } {
			if { $_cgi_uservar(from) == "view" } {
				set VIEW_FLAG 1
			}
		}
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "edit_form"
		if $VIEW_FLAG {
			set _cgi_uservar(action) "view"
		} else {
			set filename [file dirname $filename]
		}
		global conf
		read_full_env $filename fas_env
		set filetype [guess_filetype $filename conf fas_env]
		#puts "Ready to display the directory"
		display_file $filetype $filename fas_env conf
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
		set real_filename [fas_name_and_dir::get_real_filename txt $filename fas_env]
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file
		return "[not_binary::content fas_env $filename txt]"
	}
}
