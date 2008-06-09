# extension for comp
# 2004/3/3 - AL - initialisation of atemt in init
set conf(extension.comp) comp
set conf(extension.com) comp

lappend filetype_list comp

# Composite type from a main template, each section
# will be filled with either txt, txt2ml, html, body of a file,
# or a procedure
# So a comp file will look like :
#  * global.template a template
#  * section_name.type (txt|txt2ml|html|htmlfile|file)
#   * case txt
#    * section_name.content
#    * section_name.entry : text or textarea
#    * section_name.entry_html : html for entering the value
#    * section_name.width, section_name.cols, section_name.rows
#   * case txt2ml
#    * section_name.content
#    * section_name.entry : text or textarea
#    * section_name.entry_html : html for entering the value
#    * text_size, textarea_width, textarea_height
#  * case html
#    * section_name.content
#    * section_name.entry : text or textarea
#    * section_name.entry_html : html for entering the value
#    * text_size, textarea_width, textarea_height
#  * case file
#    * section_name.filename
#    * section_name.env.xxxx (new keys for fas_env)
#    * section_name.conf (pair of key value output of gets)
#    * section_name._user_cgivar (pair of key value output of gets) ???
#  case input : what comes from the pipe
#    * ???

# The following problems occure with file type
#  * when there is an error that occures when a file
#    is displayed, I have some kind of crash.
#  * the error_string is displayed in many places and not only
#    at the end of the page. Moreover it repeats also at the
#    bottom. I am going to reset error_string when it is displayed.
#    I am going to create a global IN_COMP variable. If it is at one
#    I will not show the debug and keep it for the end. So before
#    going out of comp, I will set it to 0

namespace eval ::comp {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	# I try to avoid having loops on the same file :
	#  as a comp file may include a file, it may
	#  include itself. COMP_COUNTER is here to avoid
	# keep track of that.
	set COMP_COUNTER 0

	namespace eval html {
		set local_conf(textarea.defaultrows) 10
		set local_conf(textarea.defaultcols) 30
		set local_conf(textentry.defaultwidth) 30
		set local_conf(filename.defaultwidth) 40
		proc get_html { current_env current_comp current_content section filename args } {
			# Basically, I have in current_content
			# the content to send back. I will check for
			# body and extract the body content
			upvar $current_comp comp
			upvar $current_content form_content
			if { [info exists form_content(${section}.content)] } {
				set content $form_content(${section}.content)
			} else {
				set content ""
			}
			return $content
		}
		# Functions for generating the html to edit the html
		# TO BE DONE WARNING - I SHOULD USE ALSO A TEMPLATE HERE TO DEFINE
		# THE HTML. IT WOULD BE MORE FLEXIBLE.
		proc edit_html { current_env current_comp current_content section filename } {
			# Basically, I have in current_content
			# the content to edit.
			upvar $current_comp comp
			upvar $current_content form_content

			variable local_conf

			::comp::fas_debug "::comp::html::edit_html"
			# Something to take from the input
			if { [info exists _cgi_uservar(${section})] } {
				set content $_cgi_uservar(${section})
			} else {
				if { [info exists form_content(${section}.content)] } {
					set content $form_content(${section}.content)
				} else {
					set content ""
				}
			}
			# Now, do I need a textarea or a textentry
			# And what are the size of these elements ?
			# This will be stored in comp
			# default will be textarea ?
			set html ""
			if { [info exists comp(${section}.title) ] } {
				append html "$comp(${section}.title)"
			}
			if { [info exists comp(${section}.textentry) ] } {
				set width $local_conf(textentry.defaultwidth)
				if { [info exists comp(${section}.width)] } {
					set width $comp(${section}.width)
				}
				append html "<input name=\"${section}\" value=\"${content}\" size=\"${width}\">"
			} else {
				set cols $local_conf(textarea.defaultcols)
				set rows $local_conf(textarea.defaultrows)
				if { [info exists comp(${section}.cols)] } {
					set cols $comp(${section}.cols)
				}
				if { [info exists comp(${section}.rows)] } {
					set rows $comp(${section}.rows)
				}
				append html "<textarea name=\"${section}\" rows=\"${rows}\" cols=\"${cols}\">${content}</textarea>"
			}
			return $html
		}
		proc get_txt4index { current_env current_comp current_content section filename args } {
			# Basically, I have in current_content
			# the content to send back. I will check for
			# body and extract the body content
			upvar $current_comp comp
			upvar $current_content form_content
			if { [info exists form_content(${section}.content)] } {
				regsub -all {<[^>]+>} $content {} content
			} else {
				set content ""
			}
			return $content
		}
		proc mimetype {} {
			return "text/html"
		}
	}

	namespace eval txt {
		proc get_html { current_env current_comp current_content section filename args} {
			# Basically, I have in current_content
			# the content to send back. I will check for
			# body and extract the body content
			upvar $current_comp comp
			upvar $current_content form_content
			if { [info exists form_content(${section}.content)] } {
				# I just change &, < and > into corresponding
				# caracters
				set content $form_content(${section}.content)
				regsub -all {&} $content {\&amp;} content
				regsub -all {<} $content {\&lt;} content
				regsub -all {>} $content {\&gt;} content
			} else {
				set content ""
			}
			return $content
		}
		# Functions for generating the html to edit the html
		proc edit_html { current_env current_comp current_content section filename } {
			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content
			::comp::fas_debug "::comp::txt::edit_html"
			return [::comp::html::edit_html fas_env comp form_content $section $filename]
		}
		proc get_txt4index { current_env current_comp current_content section filename args} {
			fas_debug "comp::txt::get_txt4index - entering section : $section - filename : $filename"
			# Basically, I have in current_content
			# the content to send back. I will check for
			# body and extract the body content
			upvar $current_comp comp
			upvar $current_content form_content
			if { [info exists form_content(${section}.content)] } {
				set content $form_content(${section}.content)
			} else {
				set content ""
			}
			fas_debug "comp::txt::get_txt4index - content : $content"
			return $content
		}
		proc mimetype {} {
			return "text/plain"
		}
	}

	namespace eval password {
		set local_conf(defaultwidth) 10
		proc get_html { current_env current_comp current_content section filename args} {
			return "******************"
		}
		# Functions for generating the html to edit the html
		proc edit_html { current_env current_comp current_content section filename } {
			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content
			variable local_conf
			::comp::fas_debug "::comp::password::edit_html"
			set width $local_conf(defaultwidth)
			if { [info exists comp(${section}.width)] } {
				set width $comp(${section}.width)
			}
			set html "<input type=\"password\" name=\"${section}\" value=\"\" size=\"${width}\">"
			return "$html"
		}
		proc get_txt4index { current_env current_comp current_content section filename args} {
			return ""
		}
	}


	namespace eval txt2ml {
		proc get_html { current_env current_comp current_content section filename args} {
			# Basically, I have in current_content
			# the content to send back. I will check for
			# body and extract the body content
			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content
			if { [info exists form_content(${section}.content)] } {
				# I need to have txt2ml going on that
				# I am going to try to use existing functions
				set content_txt2ml $form_content(${section}.content)
				# Now I do something special
				# I can provide new env variables from
				#    the form file.
				# I must first copy the current environment variables
				# I check if there are $section.env.xxx keys
				# defined. If it exists, I then create
				#  xxx key in the env array
				# I do that only if $section.env.xxx exists
				array set new_env [comp::form_env fas_env comp $section]
				# comp::fas_debug_parray new_env "comp::txt2ml::get_html - new_env"
				# Now I try to ask for the display
				set content [extract_body [txt::content2fashtml new_env $content_txt2ml -t "from comp" -nti]]
			} else {
				set content ""
			}
			return $content
		}
		# Functions for generating the html to edit the html
		proc edit_html { current_env current_comp current_content section filename } {
			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content
			::comp::fas_debug "::comp::txt2ml::edit_html"
			return [::comp::html::edit_html fas_env comp form_content $section $filename]
		}
		proc get_txt4index { current_env current_comp current_content section filename args} {
			# Basically, I have in current_content
			# the content to send back. I will check for
			# body and extract the body content
			upvar $current_comp comp
			upvar $current_content form_content
			if { [info exists form_content(${section}.content)] } {
				set content $form_content(${section}.content)
			} else {
				set content ""
			}
			return $content
		}
	}
	namespace eval image {
		set local_conf(textentry.defaultwidth) 20
		proc get_html { current_env current_comp current_content section filename args } {
			# Basically, I have in current_content
			# the content to send back. I will check for
			# body and extract the body content
			upvar $current_comp comp
			upvar $current_content form_content
			if { [info exists form_content(${section}.content)] } {
				set content "<img src=\"$form_content(${section}.content)\""
				if { [info exists form_content(${section}.id)] } {
					append content "id=\"$form_content(${section}.id)\" "
				}
				if { [info exists form_content(${section}.class)] } {
					append content "class=\"$form_content(${section}.class)\" "
				}
				append content ">"
			} else {
				set content ""
			}
			return $content
		}
		# Functions for generating the html to edit the image
		# I am going to show the image and the url of the
		# image
		proc edit_html { current_env current_comp current_content section filename } {
			# Basically, I have in current_content
			# the content to edit.
			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content

			variable local_conf

			::comp::fas_debug "::comp::image::edit_html"
			# Something to take from the input
			set content ""
			if { [info exists _cgi_uservar(${section})] } {
				set content $_cgi_uservar(${section})
			} elseif { [info exists form_content(${section}.content)] } {
					set content $form_content(${section}.content)
			}
			# Now, I display the image and a small text
			# entry with just the url
			set html ""
			if { [info exists comp(${section}.title) ] } {
				append html "$comp(${section}.title)"
			}
			set width $local_conf(textentry.defaultwidth)
			if { [info exists comp(${section}.width)] } {
				set width $comp(${section}.width)
			}
			# Finding the url
			append html "$content<br>[get_html fas_env comp form_content $section $filename ]<input name=\"${section}\" value=\"${content}\" size=\"${width}\">"
			return $html
		}
		proc get_txt4index { current_env current_comp current_content section filename args } {
			return ""
		}
	}

	namespace eval file {
		set safe_cgi_uservar_list ""
		# Save current _cgi_uservar and reset them
		proc save_cgi_uservar { } {
			global _cgi_uservar
			set old [array get _cgi_uservar]
			array unset _cgi_uservar
			#array set _cgi_uservar ""
			return $old
		}

		# Restore cgi_uservar from an array
		proc restore_cgi_uservar { restore_cgi_uservar_list } {
			global _cgi_uservar
			array unset _cgi_uservar
			array set _cgi_uservar $restore_cgi_uservar_list
		}

		proc set_safe_cgi_uservar { key args } {
			# First getting the value
			variable safe_cgi_uservar_list
			array set local_cgi_uservar $safe_cgi_uservar_list
			if { [info exists local_cgi_uservar($key)] } {
				return $local_cgi_uservar($key)
			} else {
				error "comp::file::set_sage_cgi_uservar [translate "no"] $key [translate "found in cgi_uservar"]"
			}
		}

		# Extract from form the _cgi_uservar orders
		proc form_to_cgi_uservar { current_comp section } {
			upvar $current_comp comp
			# I can provide cgi_uservar variables from
			# the form file.
			# I check if there are $section.env.xxx keys
			# defined. If it exists, I then create
			#  xxx key in the env array
			# I do that only if $section.env.xxx exists
			global _cgi_uservar
			set key_list [array names comp ${section}.cgi_uservar.*]
			comp::fas_debug "comp::file::form_to_cgi_uservar key_list -> $key_list"
			if { [llength $key_list] > 0 } {
				foreach long_key $key_list {
					regsub {^[^\.]+\.cgi_uservar\.} $long_key {} key
					comp::fas_debug "comp::file::form_to_cgi_uservar - key $key -> $comp($long_key)"
					set _cgi_uservar($key) $comp($long_key)
				}
			}
			# There is a special case : treedir url_start
			# I need to put it in the imported variables. So I create
			# a special order : cgi_uservar_import, and I take this
			# value from the saved values
			set key_list [array names comp ${section}.cgi_uservar_import.*]
			if { [llength $key_list] > 0 } {
				foreach long_key $key_list {
					regsub {^[^\.]+\.cgi_uservar_import\.} $long_key {} key
					# So I have a name, the value
					# is not important. I take it from
					# the saved cgi_uservar values
					if { [catch { set _cgi_uservar($key) "[set_safe_cgi_uservar $key]" }] } {
						# I do not do anything
						comp::fas_debug "comp::file::form_to_cgi_uservar - no key $key"
					} else {
						comp::fas_debug "comp::file::form_to_cgi_uservar - key $key - $_cgi_uservar($key)"
					}
				}
			}

			comp::fas_debug_parray _cgi_uservar "comp::file::form_to_cgi_uservar _cgi_uservar"
		}

		# Remove all form tags and input tags while displaying
		# a file block in an edit form. If I do not do that
		# form tags are messed up, and normal entries are not
		# shown.
		proc clean_form { content } {
			# I must find and replace all form tags
			# and input hidden tags
			regsub -all {< *[Ff][Oo][Rr][Mm][^>]*>} $content {<!-- SUPPRESSED FORM -->} content
			regsub -all {< */[Ff][Oo][Rr][Mm][^>]*>} $content {<!-- SUPPRESSED END FORM -->} content
			# hidden tags
			regsub -all {< *[Ii][Nn][Pp][Uu][Tt][^>]*>} $content {<!-- SUPPRESSED INPUT -->} content
			return $content
		}

		# If there is a -no_form argument, then all form tags
		# are suppressed from the html
		proc get_html { current_env current_comp current_content section filename args } {
			comp::fas_debug "comp::file::get_html entering"

			# Trying to avoid infinite loops
			variable ::comp::COMP_COUNTER
			comp::fas_debug "comp::file::get_html COMP_COUNTER -> $COMP_COUNTER"

			if { $::comp::COMP_COUNTER >= 4 } {
				comp::fas_debug "comp::file::get_html - warning infinite loop - going out of it"
				return ""
			}
			# Basically, I have in filename, the name of the file
			# Then, there are the options (action, ...) to save
			# in _cgi_uservar. Then I ask for the display of
			# the file and get the content. Extract the body.
			# And include the content.
			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content

			# Now I save the _cgi_uservar, and force
			# the values in comp
			global _cgi_uservar
			variable safe_cgi_uservar_list
			set safe_cgi_uservar_list [save_cgi_uservar]
			form_to_cgi_uservar comp $section
			# I force the fact that there must be no
			# menu
			set current_action ""
			if { [info exists _cgi_uservar(action)] } {
				set current_action $_cgi_uservar(action)
			}
			set _cgi_uservar(new_type_option) "notmpl"
			#set _cgi_uservar(target) "fashtml"
			comp::fas_debug_parray _cgi_uservar "comp::file::get_html - _cgi_uservar"

			# Name of the file to process
			# Either there is form_content(${section}.filename)
			# or given through _cgi_uservar
			# or I take the name of the current file
			if { [info exists form_content(${section}.filename)] } {
				set filename [add_root $form_content(${section}.filename)]
			} elseif { [info exists _cgi_uservar(filename)] } {
				set filename [add_root $_cgi_uservar(filename)]
			}
			main_log "Processing file [rm_root $filename]"
			foreach {cgivar value} [array get _cgi_uservar] {
				main_log "                  - $cgivar <= $value"
			}

			global conf
			# First saving the dependencies and initialising
                        # Doing that all dependencies are considered for the current file
                        # However, I must set a dependency for the current file
                        # So I need to have the filename :


			# TESTING THE FACT TO KEEP THE DEPENDENCIES IN THE FINAL FILE
			fas_depend::save_dependencies
			#fas_depend::init_dependencies
			# And I can ask for the current file
			read_full_env $filename current_file_env
			# Saving language and forcing it
			set original_language [international::language]
			if { [info exists current_file_env(language)] } {
				international::init_language $current_file_env(language)
			} else {
				international::init_language en
			}
			# Now the filetype
			set file_type [guess_filetype $filename conf current_file_env ]
			
			fas_debug "comp::file::get_html - extract_body display_file $file_type $filename current_file_env conf -nod"
			set tmp_content [display_file $file_type $filename current_file_env conf -nod]
			#fas_debug "comp::file::get_html - display_file -+$tmp_content +-"
			set content [extract_body $tmp_content]
			#fas_debug "comp::file::get_html - body content : $content"

			# if -no_form option, I suppress all forms indication
			if { [llength $args] > 0 } {
				set content [clean_form $content]
			}
			# Beware, I must process the dependencies
			set name_of_current_file [fas_name_and_dir::get_real_filename $file_type $filename fas_env]
			fas_depend::restore_dependencies
			fas_depend::set_dependency $name_of_current_file file
			# 4 lines with fas_depend:: removed for testing

			restore_cgi_uservar $safe_cgi_uservar_list
			# Also restoring the language
			international::init_language $original_language
			# I must also put to 0 the done of the action namespace or
			# I may have problem processing two sections having the same action
			fas_debug "::comp::file::get_html before resetting ::{current_action}::done"
			if { [info exists ::${current_action}::done] } {
				set ::${current_action}::done 0
				fas_debug "::comp::file::get_html resetting ::{current_action}::done"
			}
			return $content
		}
		# Functions for generating the html to edit the html
		# TO BE DONE WARNING - I SHOULD USE ALSO A TEMPLATE HERE TO DEFINE
		# THE HTML. IT WOULD BE MORE FLEXIBLE.
		proc edit_html { current_env current_comp current_content section filename } {
			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content
			# Basically : a textentry with the filename
			# plus a graphic button for calling a page for file selection
			variable local_conf

			# Is there something to import ?
			global _cgi_uservar
			if { [info exists _cgi_uservar(${section})] } {
				set content $_cgi_uservar(${section})
			} else {
				if { [info exists form_content(${section}.filename)] } {
					set content $form_content(${section}.filename)
				} else {
					set content ""
				}
			}
			#set width $local_conf(filename.defaultwidth)
			set width 40
			if { [info exists comp(${section}.width)] } {
				set width $comp(${section}.width)
			}
			set icons_url [fas_name_and_dir::get_icons_dir]
			set html "<input name=\"${section}\" value=\"${content}\" size=\"${width}\"><input type=\"image\" name=\"${section}.fs\" src=\"${icons_url}/select_file.gif\" border=\"0\">"
			return $html
		}
		proc get_txt4index { current_env current_comp current_content section filename args } {
			comp::fas_debug "comp::file::get_txt4index entering"

			upvar $current_env fas_env
			upvar $current_comp comp
			upvar $current_content form_content

			set content [eval get_html fas_env comp form_content "$section" "$filename" $args]
			regsub -all {<[^>]+>} $content {} content

			return $content
		}
	}

	# new_env is the output of this function
	# based on current_env + all $section.env.key defined in current_comp
	proc form_env { current_env current_comp section } {
		upvar $current_env fas_env
		upvar $current_comp comp
		# I can provide new env variables from
		#    the form file.
		# I must first copy the current environment variables
		# I check if there are $section.env.xxx keys
		# defined. If it exists, I then create
		#  xxx key in the env array
		# I do that only if $section.env.xxx exists
		if { [llength [array names comp ${section}.env.*]] > 0 } {
			array set new_env [array get fas_env]
			foreach long_key [array names comp ${section}.env.*] {
				regsub {^[^\.]\.env\.} $long_key {} key
				set new_env($key) $comp($long_key)
			}
			return [array get new_env]
		} else {
			#fas_debug_parray fas_env "comp::form_env - returning fas_env"
			return [array get fas_env]
		}
	}

	proc new_type { current_env filename } {
		fas_fastdebug {comp::new_type $filename}

		upvar $current_env fas_env
		# This is the default answer
		set result fashtml
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			# there is an action. Is it done or not
			if { $action != "view" } {
				if { [set ${action}::done ] == 0 } {
					fas_debug "comp::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			} ; # action is view, I continue
		}
		if { ![catch {set target [fas_get_value target -noe]}] } {
			# we are in the standard case nothing to do
			switch -exact -- $target {
				comp {
					# I stop here
					#error 1
					return ""
				}
				txt4index {
					set result txt4index
				}
				rrooll -
				rool {
					fas_debug_parray fas_env "comp::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "comp::new_type fas_env after down_stage_env with rool"
					return "rrooll"
				}
			}
		}
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list fashtml txt4index]
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
		#lappend env_list [list "comp.comp" "Env file defining the template, and the elements displayed for a file" webmaster]
                #lappend env_list [list "new.comp.form_list" "The list of template available for this file" webmaster]
		lappend env_list [list "new.comp.form_list" "List of possible comp type that may be created. Beware this the an exact match with path and extension." webmaster]
		lappend env_list [list "compdir" "Directory where comp files are stored." admin]
		lappend env_list [list "view.comp" "Form to use to display this file. \"{form_dir}/{file_type}.view.form\" is the standard value" webmaster]
		return $env_list
	}

	#
	# Initialisation of crucial variables
	#
	proc init { } {
		set ::comp::file::safe_cgi_uservar_list ""
		set ::comp:COMP_COUNTER 0
		# Maybe would it be a good idea to reinitialise atemt::_atemt
		::atemt::init
	}

	# if this function exists, then it is possible to
	# create a new comp with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf dirname filename filetype ON_EXTENSION_FLAG } {
		# WARNING : what about an existing file ? I should warn
		# the creator !!!!
		fas_debug "comp::new - $dirname $filename $filetype $ON_EXTENSION_FLAG current_env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		set new::done 1

		# What is the real file to create
		set full_filename [file join $dirname $filename]
		fas_debug "comp::new - creating file $full_filename"

		# Do I know which form file to use
		global _cgi_uservar
                # If there is only one kind of form to add,
                # Then I do not present the file, I just ask
                # for this one.
                if { [info exists fas_env(new.comp.form_list)] } {
                        if { [llength $fas_env(new.comp.form_list)] == 1 } {
                                set _cgi_uservar(comp.####) [lindex $fas_env(new.comp.form_list) 0]
                        }
                }

		# Do I have some values that where previously defined
		# It may be #### or any other value for the comp
		# All comp.xxxx are taken stored in an array and
		# then written to a file
		foreach key [array names _cgi_uservar comp.*] {
			set clean_key $key
			regsub {^comp\.} $key {} clean_key
			set current_comp($clean_key) $_cgi_uservar($key)
		}

		# So do I now the comp to use or not ?
		if { [info exists _cgi_uservar(comp.####)] } {
			if { [file readable $full_filename] } {
				fas_display_error "[translate "Beware "] $full_filename [translate "exists"]" fas_env -f $dirname
			}
			if { [catch {write_env $full_filename current_comp} ] } {
				fas_display_error "[translate "Impossible to open "] $full_filename [translate " for writing"]" fas_env -f $dirname
			} else {
				# So I have created a file, now I will create the
				# property file if necessary
				if { !${ON_EXTENSION_FLAG} } {
					# I force the filetype
					set new_env(file_type) $filetype
					# I write the env file
					global shadow_dir
					write_env [file join $dirname $shadow_dir $filename] new_env
					set fas_env(file_type) $filetype
				}
				# And now the real high tech
				# I am going to jump to the edition page
				# on this empty file. So I need to cleanup
				global _cgi_uservar
				unset _cgi_uservar
				set _cgi_uservar(action) edit_form
				global DEBUG
				set _cgi_uservar(debug) $DEBUG

				display_file $filetype $full_filename fas_env fas_conf
				# And I exit as something will be displayed
				fas_exit
			}
		} else {
                        set current_form_list [fas_get_value new.comp.tmpl_list]
			# I must present a page for asking
			# for the form to use to create
			# a new comp file
			# It may come either from an env variable
			# or from a list
                        # So as usual :
                        # First load a template,
                        # then iterate over a list either from a directory
                        # or from a variable
                        # Extract a title variable from the corresponding file
                        # Display that in offering for a title in front of the variable
                        # Plouf that's it
                        # The goal is to prepare for a variable comp.form
                        # which must hold a full form variable

		}

	}

	proc mimetype { } {
		return "text/html"
	}

	proc ucome_doc { } {
		set content {Composite files. These files allow to describe different parts of a final file. Each part may be itself of different sort. A part of a composite file may be pure txt, txt2ml, html. It may refer to another part of the composite file (a block) or it may be a file. If it is a file, then UCome is used to display the file. Then variables may be passed to UCome as if it was called from a navigator.
 
The file controlling to what correspond each file part is called a form file. OK, ok, this vocabulary is confusing. I accept an other one if you wish to suggest.
 
The format of the file is :

key1 value1 key2 value2 ...

A value may span on multiple lines then it is enclosed in { }. It is the format of an "array get" in tcl.}
		return $content
	}

	proc 2rrooll { current_env filename args } {
		fas_fastdebug {comp::2rrooll $filename}
		upvar $current_env fas_env

		set fas_env(rrooll.command) "fashtml::content2htmf fas_env \[::comp::2fashtml fas_env ${filename}\] ${args}"

		return "[fashtml::content2htmf fas_env [::comp::2fashtml fas_env ${filename}] ${args}]"
	}

	# This procedure will translate a comp into html
	# This is very arbitrary, as it may also be seen as pure 
	# html. It is just conf(newtype.txt) that will say
	# how it will be changed (in which cache directory it will be
	# written).

	# KNOWN BUG : if a message is given at input, it will not
	# appear on the html which is created.
	proc 2fashtml { current_env filename {filetype comp}} {
		fas_debug "comp::2fashtml - entering with filename->$filename and filetype->\'$filetype\'"

		upvar $current_env fas_env
		global conf

		# I must say that I start displaying a comp.
		# Then I must stop giving out the debug messages
		global IN_COMP

		set real_filename [fas_name_and_dir::get_real_filename $filetype $filename fas_env]

		# I put the structure of the form in an array
		if { [catch {read_env $real_filename form_content} error] } {
			fas_display_error "comp::2fashtml - [translate "Problem while reading form file "] $real_filename<br>$error" fas_env -f $filename
		}
		fas_debug "comp::2fashtml $filename - $real_filename read successfully"

		# There must be a #### element that gives the corresponding
		# form
		if { ![info exists form_content(####)] } {
			# Normaly it is a cached file which is entering. Then we use
			# the default value
			fas_debug "comp::2fashtml $filename - use default form_content"
			set corresponding_form [add_root [fas_name_and_dir::get_comp_name fas_env $filename $filetype]]
		} else {
			# This is the name of the form
			fas_debug "comp::2fashtml $filename - use form_content(####) : [add_root ${form_content(####)}] "
			set corresponding_form [add_root $form_content(####)]
		}
		fas_debug "<div bgcolor=\"#ffA0A0\">comp::2fashtml - current form is $corresponding_form</div>"
		main_log "Using form [rm_root $corresponding_form]"

		# So now I load the form itself
		if { [ catch { read_env $corresponding_form comp } ] } {
			return "<h1>[translate "Problem while reading $corresponding_form"]</h1>"
		}

		fas_debug_parray comp "comp::2fashtml - comp"

		# First is there an include section ????
		# If there is, I will include the value of it in
		# the current comp but not overwrite existing values.
		if { [info exists comp(global.include)] } {

			fas_debug "comp::2fashtml $filename - using global.include"
			# So there is an include section
			# I am going to include it
			set include_form [add_root [file join [fas_name_and_dir::get_comp_dir fas_env] $comp(global.include)]]
			if { ![catch {read_env $include_form include_comp} ] } {
				fas_debug "comp::2fashtml - including $include_form"
				foreach name [array names include_comp] {
					if { ![info exists comp($name)] } {
						set comp($name) $include_comp($name)
					}
				}
				fas_debug_parray comp "Final comp after inclusion of $include_form"
			}
		}

		# I get the section list :
		set section_type_list [array names comp "*.type"]

		# And I get the section
		set section_list ""
		foreach bad_sect $section_type_list {
			regsub {\.type$} $bad_sect {} current_section
			lappend section_list $current_section
		}
		fas_debug "comp::2fashtml $filename - retrieved section list :\n\{$section_list\}"

		# Now I must review one after the other the section
		# and get the corresponding html
		set IN_COMP 1
		variable COMP_COUNTER
		set block_section_list ""
		foreach section $section_list {
			set type $comp(${section}.type)
			fas_debug "comp::2fashtml - processing section $section of type $type"
			main_log "Processing section $section of type $type"
			if { ( $type == "txt" ) || ( $type == "html" ) || ( $type == "txt2ml" ) || ( $type == "file" ) || ( $type == "htmlfile" ) || ( $type == "password" ) || ($type == "image")} {
				fas_debug_parray ::_cgi_uservar "comp::2fashtml - before entering in section $section _cgi_uservar"
				if { [catch {incr COMP_COUNTER;set comp(${section}.html) [comp::${type}::get_html fas_env comp form_content $section $filename]} error ] } {
					# fas_display_error "comp::2fashtml - [translate "Problem while processing section "] $section" fas_env
					set comp(${section}.html) "[translate "Problem while processing section "] $section <br>$error"
					incr COMP_COUNTER -1
				} else {
					incr COMP_COUNTER -1
				}
				fas_debug_parray ::_cgi_uservar "comp::2fashtml - _cgi_uservar - after entering in section $section"
			} elseif { $type == "block" } {
				lappend block_section_list $section
				set comp(${section}.html ""
			} else {
				set comp(${section}.html) "[translate "Unknown section type :"] $type"
			}
			# fas_debug "comp::2fashtml - comp(${section}.html) -> $comp(${section}.html)"   
		}

		# Now processing the section of type block :
		foreach section $block_section_list {
			if { [info exists comp(${section}.block)] } {
				set target_block $comp(${section}.block)
				if { [info exists comp(${target_block}.html)] } {
					set comp(${section}.html) $comp(${target_block}.html)
				}
			}
		}
		# I am out of the get_html section
		set IN_COMP 0
		fas_depend::set_dependency $corresponding_form file
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file


		# So I have the html for each section, now I just
		# put it in the corresponding section of the file
		if { ![info exists comp(global.template)] } {
			# I use this template
			fas_debug "comp::2fashtml - comp(global.template) is not defined => error"
			fas_debug_parray comp "comp::2fashtml - comp - before error as global.template is undefined"
			fas_display_error "comp::2fashtml - [translate "No template define for current form "] [rm_root $corresponding_form] for comp file [rm_root $filename]" fas_env
			fas_exit
		}
		# else => I should create an automatic empty template
		# that would just be the agregation of the different parts
		
		set form_name [fas_name_and_dir::get_template_name_from_comp fas_env comp]
		fas_depend::set_dependency $form_name file
		atemt::read_file_template_or_cache "TEMPLATE" "$form_name"

		# Ooopps - icons url is always useful
		set icons_url [fas_name_and_dir::get_icons_dir]
		set file [rm_root $filename]
		set dir [file dirname $file]

		# I try that : to substitute icons_url in the whole template
		#set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -all TEMPLATE] 
		#atemt::atemt_set TEMPLATE -bl [atemt::atemt_subst -all TEMPLATE] 
		#fas_fastdebug {comp::2fashtml - atemt::atemt_subst -all TEMPLATE => $::atemt::_atemt(TEMPLATE)}
		#fas_debug_parray ::atemt::_atemt {comp::2fashtml -  parray ::atemt::_atemt}

		# OK now I have all the sections and I use it
		#fas_debug_parray atemt::_atemt "comp::2fashtml - atemt::_atemt - before any insertion"	
		fas_debug "comp::2fashtml - template section list : [atemt::get_block_list $form_name]"
		foreach section $section_list {
			set template_section_name [string toupper $section]
			atemt::set_html $template_section_name $comp(${section}.html)
			#fas_fastdebug {comp::2fashtml - putting in $template_section_name comp(${section}.html) ######$comp(${section}.html) #########}
			set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -vn -block $template_section_name TEMPLATE]
			#fas_debug_parray atemt::_atemt "comp::2fashtml - atemt::_atemt after processing of $section"
		}

		# Just have to finalise it ????
		# Maybe I should set some default variables and substitute them
		set IN_COMP 0
		#fas_fastdebug {comp::2fashtml - ::atemt::_atemt(TEMPLATE) $::atemt::_atemt(TEMPLATE)}
		#fas_fastdebug {comp::2fashtml - finalizing [atemt::atemt_subst -end TEMPLATE]}
		#fas_fastdebug {comp::2fashtml - after finalizing ::atemt::_atemt(TEMPLATE) $::atemt::_atemt(TEMPLATE)}
		set result [atemt::atemt_subst -end TEMPLATE]
		fas_debug "comp::2fashtml returned $result"
		return $result
	}

	# This procedure will translate a comp into an editable html
	# It is only available for "real" comp file, not those
	# coming from a pipe.
	# I also use this function for other filetypes such as todo
	# or password. It changes the dependencies hence the last argument
	proc 2edit_form { current_env filename {comp_filetype comp} } {
		upvar $current_env fas_env
		global conf

		fas_debug "comp::2edit_form - entering 2edit_form"
		# I must say that I start displaying a comp.
		# Then I must stop giving out the debug messages
		global IN_COMP
		set IN_COMP 1

		set real_filename [fas_name_and_dir::get_real_filename $comp_filetype $filename fas_env]

		fas_debug "comp::2edit_form - real_filename -> $real_filename"
		# I put the structure of the form in an array
		if { [catch {read_env $real_filename form_content} error] } {
			fas_display_error "comp::2edit_form - [translate "Problem while reading form file "] $real_filename<br>$error" fas_env
		}

		# There must be a #### element that gives the corresponding
		# form
		if { ![info exists form_content(####)] } {
			set corresponding_form [add_root [fas_name_and_dir::get_comp_name fas_env $filename]]
		} else {
			# This is the name of the form
			set corresponding_form [add_root $form_content(####)]
		}
		fas_debug "comp::2edit_form - current form is $corresponding_form"
		main_log "comp::2edit_form - current form is $corresponding_form"

		# So now I load the form itself
		read_env $corresponding_form comp
		fas_debug_parray comp "comp::2edit_form - comp"

		# I get the section list :
		set section_type_list [array names comp "*.type"]

		# And I get the section
		set section_list ""
		foreach bad_sect $section_type_list {
			regsub {\.type$} $bad_sect {} current_section
			lappend section_list $current_section
		}

		fas_debug "comp::2edit_form - section_list => $section_list"
		set block_section_list ""
		# Now I must review one after the other the section
		# and get the corresponding html
		foreach section $section_list {
			set type $comp(${section}.type)
			fas_debug "comp::2edit_form - processing section $section of type $type"
			if { ![info exists comp(${section}.no_edit)] } {
				fas_debug "comp::2edit_form - section $section is editable"
				# I can edit this section
				if { ( $type == "txt" ) || ( $type == "html" ) || ( $type == "txt2ml" ) || ( $type == "file" ) || ( $type == "password" ) || ( $type == "image") } {
					# First, I try to edit the content dependending of the block type
					if { [catch {set comp(${section}.html) [::comp::${type}::edit_html fas_env comp form_content $section $filename]} error ] } {
						set comp(${section}.html) "[translate "Problem while editing section "] $section <br>$error"
					}
					fas_debug "comp::2edit_form - section $section is txt, html, txt2ml or file -> $comp(${section}.html)"
				} elseif { $type == "block" } {
					lappend block_section_list $section
					set comp(${section}.html) ""
					fas_debug "comp::2edit_form - section $section is block -> $comp(${section}.html)"
				} else {
					set comp(${section}.html) "[translate "Unknown section type :"] $type"
				}
			} else {
				fas_debug "comp::2edit_form - section $section NOT editable"
				# But I do not want this one to be edited
				if { ( $type == "txt" ) || ( $type == "html" ) || ( $type == "txt2ml" ) || ( $type == "file" ) || ( $type == "htmlfile" ) || ( $type == "password" ) || ($type == "image") } {
					variable COMP_COUNTER
					if { [catch {incr COMP_COUNTER;set comp(${section}.html) [::comp::${type}::get_html fas_env comp form_content $section $filename -no_form]} error ] } {
						# fas_display_error "comp::2fashtml - [translate "Problem while processing section "] $section" fas_env
						set comp(${section}.html) "[translate "Problem while processing section "] $section <br>$error"
						incr COMP_COUNTER -1
					} else {
						incr COMP_COUNTER -1
					}
				} elseif { $type == "block" } {
					lappend block_section_list $section
					set comp(${section}.html) ""
				} else {
					set comp(${section}.html) "[translate "Unknown section type :"] $type"
				}
			}
			# fas_debug "comp::2fashtml - comp(${section}.html) -> $comp(${section}.html)"   
		}
		# I am out of the get_html section
		set IN_COMP 0
		fas_depend::set_dependency $corresponding_form file
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file


		# So I have the html for each section, now I just
		# put it in the corresponding section of the file
		if { ![info exists comp(global.template)] } {
			# I use this template
			fas_display_error "comp::2edit_form - [translate "No template define for current form "]" fas_env
			fas_exit
		}
		
		set form_name [fas_name_and_dir::get_template_name_from_comp fas_env comp]
		fas_depend::set_dependency $form_name file
		atemt::read_file_template_or_cache "TEMPLATE" "$form_name"

		# Ooopps - icons url is always useful
		set icons_url [fas_name_and_dir::get_icons_dir]
		set file [rm_root $filename]
		set dir [file dirname $file]
		# I try that : to substitute icons_url in the whole template
		#set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -all TEMPLATE] 
		# OK now I have all the sections and I use it
		#fas_debug_parray atemt::_atemt "comp::2fashtml - atemt::_atemt - before any insertion"
		foreach section $section_list {
			fas_debug "comp::2edit_form - substituting in the template $section"
			set template_section_name [string toupper $section]
			atemt::set_html $template_section_name $comp(${section}.html)
			set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -vn -block $template_section_name TEMPLATE]
			# IF YOU HAVE A BIG PROBLEM WITH A TEMPLATE USE ONE OF THE
			# 2 FOLLOWING LINES TO UNDERSTAND WHAT IS HAPPENING.
			# THE FIRST ONE ALLOWS TO DISPLAY THE CONTENT OF TEMPLATE
			# AFTER EACH SUBSTITUTION OF A SECTION TO EDIT
			fas_debug "comp::2edit_form - TEMPLATE IS NOW ----------\n$atemt::_atemt(TEMPLATE) \n-------------------"
			#fas_debug_parray atemt::_atemt "comp::2fashtml - atemt::_atemt after processing of $section"
		}
		# Now doing the form sections
		if { [info exists atemt::_atemt(FORM_START)] && [info exists atemt::_atemt(FORM_START)] } {
			set export_filename [rm_root $filename]
			set dir [rm_root [file dirname $filename]]
			global FAS_VIEW_CGI
			set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -block FORM_START -block FORM_END TEMPLATE]
			set FORM_IN_TEMPLATE 1
		} else {
			# There are no FORM_START / FORM_END sections
			# then I add default values at start and end
			# of the form
			global FAS_VIEW_CGI
			set export_filename [rm_root $filename]
			set start_form "<form action=\"${FAS_VIEW_CGI}\"><input type=\"hidden\" name=\"file\" value=\"${export_filename}\"><input type=\"hidden\" name=\"action\" value=\"edit\">"
			set end_form "<input type=\"image\" name=\"ok\" value=\"1\"  src=\"${icons_url}/ok.gif\" border=\"0\">  <a href=\"${FAS_VIEW_CGI}?action=edit_form&file=${export_filename}\"><img src=\"${icons_url}/cancel.gif\" border=\"0\" alt=\"Annuler\"></a></form>"
			set FORM_IN_TEMPLATE 0
			
		}
		# I try that : to substitute icons_url in the whole template
		set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -all TEMPLATE] 

		# Just have to finalise it ????
		# Maybe I should set some default variables and substitute them
		set IN_COMP 0
		set result_string [atemt::atemt_subst -end TEMPLATE]
		if { !$FORM_IN_TEMPLATE } {
			# Beware !!!! I extract the body if there are
			# no FORM_START and FORM_END in the template and
			# in the comp.
			set result_string "${start_form}[extract_body $result_string]${end_form}"
		}
		#return [atemt::atemt_subst -end TEMPLATE]
		return $result_string
	}

	# Get the result of edit_form and put it in a file
	proc 2edit { current_env filename {comp_filetype comp} } {
		upvar $current_env fas_env
		global conf

		fas_debug "comp::2edit - entering 2edit current_env $filename"
		# Here there is a special case :
		# I may come here because of a click on a file selection button.
		# So I must detect that, then jump to the action corresponding, having stored everything.
		
		# I must say that I start displaying a comp.
		# Then I must stop giving out the debug messages
		set real_filename [fas_name_and_dir::get_real_filename $comp_filetype $filename fas_env]

		# I put the structure of the form in an array
		if { [catch {read_env $real_filename form_content} error] } {
			fas_display_error "comp::2edit - [translate "Problem while reading form file "] $real_filename<br>$error" fas_env
		}

		# There must be a #### element that gives the corresponding
		# form
		if { ![info exists form_content(####)] } {
			set corresponding_form [add_root [fas_name_and_dir::get_comp_name fas_env $filename $comp_filetype]]
		} else {
			# This is the name of the form
			set corresponding_form [add_root $form_content(####)]
		}
		fas_debug "comp::2edit - current form is $corresponding_form"

		# So now I load the form itself
		read_env $corresponding_form comp
		fas_debug_parray comp "comp::2edit - comp"

		# I get the section list :
		set section_type_list [array names comp "*.type"]

		# And I get the section
		set section_list ""
		foreach bad_sect $section_type_list {
			regsub {\.type$} $bad_sect {} current_section
			lappend section_list $current_section
		}

		global _cgi_uservar
		# First detecting if I am in the case of file selection
		set SELECT_FILE_FLAG 0
		set select_section ""
		foreach section $section_list {
			if { [info exists _cgi_uservar(${section}.fs.x)] } {
				# we are in the file selection case
				# Now ???
				set SELECT_FILE_FLAG 1
				set select_section $section
			}
		}

		if { $SELECT_FILE_FLAG } {
			# I must go toward something else
			# First, I unset fs.x and fs.y
			# I force action to edit_form
			# I hope file is still valid
			# And I store that in a session variable
			unset _cgi_uservar(${select_section}.fs.x)
			unset _cgi_uservar(${select_section}.fs.y)
			# I just put an action edit_form, as I come from that
			set _cgi_uservar(action) edit_form
			set current_file "[rm_root $filename]"
			if { [info exists _cgi_uservar(${section}.filename)] } {
				set current_file $_cgi_uservar(${section}.filename)
			}
			# Now I need a directory
			if { [file isdirectory [add_root $current_file]] } {
				# nothing to do
			} else {
				set current_file [file dirname $current_file]
			}

			# I store that in a session variable
			fas_session::setsession _cgi_uservar [array get _cgi_uservar]
			fas_session::setsession selectsection $select_section
			fas_session::setsession comefrom "edit_form"
			fas_session::setsession filename "[rm_root $filename]"

			# And now I call a way to select a file.
			# Basically a dir to display, with a special tag file list for having a
			# selection checkbox.
			unset _cgi_uservar
			set _cgi_uservar(action) edit_form
			set _cgi_uservar(display) "filetype,shortname,extension,title,select"
			set _cgi_uservar(form) "1"
			set _cgi_uservar(noadd) "1"
			# HUM, HUM, HUM, the next one is hot
			# It is recursive. I must preserve treedir.url_start
			# within the call. Then I need to escape the special
			# chars. So I try (I am not sure that it will work).
			#set _cgi_uservar(treedir.url_start) "?action=edit_form&display=filetype,shortname,extension,title,select&form=1&noadd=1&treedir.url_start=%3faction%3dedit_form%26display=filetype,shortname,extension,title,select%26form%3d1%26noadd%3d1%26file%3d&file="
			set _cgi_uservar(treedir.url_start) "?action=show_select_file&file="
			global conf
			#puts "Ready to display the directory"
			display_file dir [add_root $current_file] fas_env conf
			fas_session::write_session
			fas_exit
		}
		# else
		# Now I must review one after the other the section
		# and import the content
		foreach section $section_list {
			set type $comp(${section}.type)
			fas_debug "comp::2edit - processing section $section of type $type"
			if { ( $type == "txt" ) || ( $type == "html" ) || ( $type == "txt2ml" ) || ( $type == "image") } {
				if { [info exists _cgi_uservar(${section})] } {
					set form_content(${section}.content) $_cgi_uservar(${section})
				}
			} elseif { $type == "file" } {
				if { [info exists _cgi_uservar(${section})] } {
					set form_content(${section}.filename) $_cgi_uservar(${section})
				}
			} elseif { $type == "password" } {
				if { [info exists _cgi_uservar(${section})] } {
					set form_content(${section}.content) [::md5::md5 -hex $_cgi_uservar(${section})]
				}
			}
		}
		# And now I save the content in the form_file
		if { [catch {write_env $real_filename form_content} error] } {
			set message "[translate "Problem while writing form file "] $real_filename<br>$error"
		} else {
			set message "[translate "Succesful composite file writing of"] [rm_root $real_filename]"
		}
		# And I jump back to the edition of the directory
		# First, doing as if the message is imported variable
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
	
		# And now asking for the display of the directory
		#set dir_name [file dirname $filename]
		#set _cgi_uservar(action) "edit_form"
		set dir_name $filename
		set filetype [guess_filetype $filename conf fas_env]
		set _cgi_uservar(action) "view"
		global conf
		#puts "Ready to display the directory"
		display_file $filetype $dir_name fas_env conf
		fas_exit

	}

	proc 2txt4index { current_env filename {filetype comp}} {
		fas_debug "comp::2txt4index - entering with $filename and $filetype"
		upvar $current_env fas_env
		global conf

		# I must say that I start displaying a comp.
		# Then I must stop giving out the debug messages
		set real_filename [fas_name_and_dir::get_real_filename $filetype $filename fas_env]

		# I put the structure of the form in an array
		if { [catch {read_env $real_filename form_content} error] } {
			fas_display_error "comp::2txt4index - [translate "Problem while reading form file "] $real_filename<br>$error" fas_env
		}

		# There must be a #### element that gives the corresponding
		# form
		if { ![info exists form_content(####)] } {
			# Normaly it is a cached file which is entering. Then we use
			# the default value
			set corresponding_form [add_root [fas_name_and_dir::get_comp_name fas_env $filename $filetype]]
		} else {
			# This is the name of the form
			set corresponding_form [add_root $form_content(####)]
		}

		# So now I load the form itself
		if { [ catch { read_env $corresponding_form comp } ] } {
			return "<h1>[translate "Problem while reading $corresponding_form"]</h1>"
		}
		fas_debug_parray comp "comp::2txt4index - $corresponding_form - comp"
		# I get the section list :
		set section_type_list [array names comp "*.type"]
		fas_debug "comp::2txt4index - section_type_list - $section_type_list"

		# And I get the section
		set section_list ""
		foreach bad_sect $section_type_list {
			regsub {\.type$} $bad_sect {} current_section
			lappend section_list $current_section
		}

		# Now I must review one after the other the section
		# and get the corresponding html
		set IN_COMP 1
		variable COMP_COUNTER
		set block_section_list ""
		set content ""
		foreach section $section_list {
			set type $comp(${section}.type)
			fas_debug "comp::2txt4index - processing section $section of type $type"
			if { ( $type == "txt" ) || ( $type == "html" ) || ( $type == "txt2ml" ) || ( $type == "file" ) || ( $type == "htmlfile" ) || ( $type == "password" ) || ( $type == "image") } {
				if { [catch {incr COMP_COUNTER;append content [comp::${type}::get_txt4index fas_env comp form_content $section $filename]} error ] } {
					append content "[translate "Problem while processing section "] $section <br>$error"
					incr COMP_COUNTER -1
					fas_debug "comp::2txt4index - error while extracting get_txt4index for section $section<br>$error"
				} else {
					incr COMP_COUNTER -1
					fas_debug "comp::2txt4index - content after $section => $content \n--------------------------"
				}
			}
		}
		# I am out of the get_html section
		set IN_COMP 0

		fas_debug "comp::txt4index - reaching end, content => $content"
		return $content
	}	

	proc get_title { filename } {
		global fas_env
		set title "[translate "Composite file"]"
		set real_filename [fas_name_and_dir::get_real_filename comp $filename fas_env]

		# I put the structure of the form in an array
		if { ![catch {read_env $real_filename form_content}] } {

			fas_debug_parray form_content "comp::get_title - form_content"
			# And I take content if it exists
			# OK, in theory, I should do a special function for each
			# different type. Load the corresponding form, look at 
			# the type of title, ... I find it boring.
			if { [info exists form_content(title.content)] } {
				set title $form_content(title.content)
			}
		}
		return $title
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
