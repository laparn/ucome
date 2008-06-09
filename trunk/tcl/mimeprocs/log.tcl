#set UCOME_LOG_BASE "${FAS_VIEW_CGI}?file=/any/internet/log/"

# extension for log
set ::conf(extension.log) logfile
 
lappend filetype_list logfile

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval logfile {
	global ::FAS_PROG_ROOT

	global ::DEBUG_PROCEDURES
	eval $::DEBUG_PROCEDURES

	global ::STANDARD_PROCEDURES
	eval $::STANDARD_PROCEDURES

	proc new_type { current_env filename } {
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
					fas_debug "log::new_type - action -> $action , action::done -> [set ${action}::done]"
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
					fas_debug_parray fas_env "log::new_type fas_env before down_stage_env"
					down_stage_env fas_env "pdf.cgi_uservar." 
					fas_debug_parray fas_env "log::new_type fas_env after down_stage_env"
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
				ori {
					set result log
					#error 1
					return ""
				}
			}
		}
		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "tmpl" ) && ( $new_type_option == "notmpl" ) } {
			set result fashtml
		}
		fas_debug "log::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list comp fashtml log pdf tmpl]
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
		upvar $current_env fas_env
		return "[eval 2fashtml fas_env $args ]"
	}
	
	proc content2tmpl { current_env args } {
		fas_debug "txt::content2tmpl - $args"
		upvar $current_env fas_env
		return "[eval content2fashtml fas_env $args ]"
	}
	
	proc 2comp { current_env filename } {
		fas_debug "log::2comp - $filename"
		puts "log::2comp - $filename"
		upvar $current_env fas_env
		global ::_cgi_uservar
	        global BASE_DIR
		global FAS_VIEW_CGI
		set UCOME_LOG_BASE "${FAS_VIEW_CGI}?file=/any/internet/log/"

		set real_filename [add_root2 $filename]
		# Basically, the output depends on the input file
		fas_depend::set_dependency $filename file
		#fas_depend::set_dependency $filename always
		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		if [catch {set fdfile [open $real_filename r]}] {
			fas_display_error "log::2comp - Could not open $real_filename" fas_env -f $filename
		}
		set content [read $fdfile]

		global ::ROOT
		regsub -all -lineanchor -- "(${::ROOT})" $content "" content
		regsub -all -lineanchor -- "((?:/\[^/ \]*)+/(\[^/\]*)\\.int(?:ernet)?)" $content     "<a href=\"${UCOME_LOG_BASE}\\2.log\">\\1</a>" content


		regsub -all -lineanchor -- "^(notice.*?)$" $content "<font color=\"blue\">\\1</font><br>" content
		set nb_error [regsub -all -lineanchor -- "^(error.*?)$" $content "<font color=\"red\">\\1</font><br>" content]
		set nb_warning [regsub -all -lineanchor -- "^(warning.*?)$" $content "<font color=\"yellow\">\\1</font><br>" content]




		set content "Nombre d'erreur: $nb_error<br>Nombre de warning: $nb_warning<br>$content"



		set tmp(content.content) $content
		close $fdfile
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

	proc get_title { filename } {
		fas_debug "log::get_title entering"
		# The title is the first line of the file
		set title ""
		if { [regexp -nocase -- ".*?(\[^/\]+)\.log?$" $filename trash basename]} {
			set title "Log of $basename.internet"
		} else {
			fas_display_error "logfile::get_title - Bad filename $filename" fas_env -f $filename
		}


		fas_debug "log::get_title found ->$title<-"
		return $title
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

}
