# extension for form
set conf(extension.form) form

lappend filetype_list form

# And now all procedures for form. How to translate into tmpl or html,
# how to display pure form.
# It is strongly inspired from txt
namespace eval form {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		# When a form is met, in what filetype will it be by default
		# translated ?
		# This is the default answer
		set result tmpl
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "form::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		if { ![catch {set target [fas_get_value target -noe]}] } {
			# we are in the standard case nothing to do
			switch -exact -- $target {
				form {
					# I throw an error I am at the end
					#error 1
					return ""
				}
				pdf  {
					set result tmpl
					# No need to write it, but it is more clear so
				}
				htmf  {
					set result tmpl
					# No need to write it, but it is more clear so
				}
				fashtml {
					set result tmpl
				}
				nomenu {
					set result fashtml
				}
			}
		}
		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "tmpl" ) && ( $new_type_option == "notmpl" ) } {
			set result fashtml
		}
		fas_debug "form::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list tmpl fashtml]
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
	# create a new form with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf args } {
		fas_debug "form::new - _env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		eval fashtml::new fas_env fas_conf $args
	}

	proc mimetype { } {
		return "text/plain"
	}



	# This procedure will translate a form into a tmpl
	# This is very arbitrary, as it may also be seen as pure 
	# html. It is just conf(newtype.txt) that will say
	# how it will be changed (in which cache directory it will be
	# written).
	proc 2tmpl { current_env args } {
		fas_debug "form::2tmpl - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2tmpl { current_env args } {
		fas_debug "form::content2tmpl - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
	}
	
	proc 2comp { current_env args } {
		fas_debug "form::2comp - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
		#return ""
	}

	proc content2comp { current_env args } {
		fas_debug "form::content2comp - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
		#return ""
	}

	# This is an idiot procedure to display rows of key value
	# It returns counter
	proc display_key_value { key_value_list counter } {
		# First looking for the type
		foreach {name content} $key_value_list {
			if { [regexp {\.type$} $name match] } {
				fas_debug "form::display_key_value - outputing $name $content"
				set atemt::_atemt(VALUE_ROW) $atemt::_atemt(VALUE_LIST)
				if { [expr $counter % 2] == 1 } {
					set atemt::_atemt(VALUE_ROW) $atemt::_atemt(VALUE_LIST_ODD)
				}
				set atemt::_atemt(ALL_VALUE_ROWS) [atemt::atemt_subst -insert -block VALUE_ROW ALL_VALUE_ROWS]
				incr counter
			}
		}
		# Now everything but the type
		foreach {name content} $key_value_list {
			if { ![regexp {\.type$} $name match] } {
				fas_debug "form::display_key_value - outputing $name $content"
				set atemt::_atemt(VALUE_ROW) $atemt::_atemt(VALUE_LIST)
				if { [expr $counter % 2] == 1 } {
					set atemt::_atemt(VALUE_ROW) $atemt::_atemt(VALUE_LIST_ODD)
				}
				set atemt::_atemt(ALL_VALUE_ROWS) [atemt::atemt_subst -insert -block VALUE_ROW ALL_VALUE_ROWS]
				incr counter
			}
		}
		return $counter
	}

	# Suppress from the array the values that where previously
	# displayed
	proc clean_array { key_value_list this_array } {
		upvar $this_array current_array

		foreach {name value} $key_value_list {
			array unset current_array $name
		}
	}
		
	
	# This procedure will translate a form into html 

	# The dependencies are the following :
	#  - eventually $env(perso.tcl), $env(style)
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename form $filename fas_env]
		set root_file [rm_root $filename]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# I put the input file in an array
		if { [catch {read_env $real_filename form_content} error] } {
			fas_display_error "form::2fashtml - [translate "Problem while reading form file "] $root_file<br>$error" fas_env
		}
		
		
		# I propose the usual trick :
                # I start from a template, and I go through the different
		# entries for displaying them :
		# First load template, then loop on the loaded values for
		# the file.
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env form.view.template] } errStr] } {
			fas_display_error "form::2fashtml - [translate "Please define fas_env variables"] view.form.template<br>${errStr}" fas_env
		}
		# setting a dependency on the template
		fas_depend::set_dependency $template_name file
		# reading the template
		if { [catch { atemt::read_file_template_or_cache "TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "form::2fashtml - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}
		# Preparing the variables
		atemt::atemt_set HEAD_TITLE "[translate "Edit form for"] [rm_root $filename]"
		atemt::atemt_set TOP_TITLE "[translate "Edit form for"] [rm_root $filename]"

		set icons_url [fas_name_and_dir::get_icons_dir]
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		set export_filename [rm_root $filename]
		set dir [rm_root [file dirname $filename]]

		# Now preparing the mundane part : title section and body_title
		set atemt::_atemt(TITLE) "[translate "Form file"] $root_file"
		set atemt::_atemt(BODY_TITLE) "[translate "File"] $root_file"

		# Well doing the substitutions :
		set atemt::_atemt(TEMPLATE) [atemt::atemt_subst  -block HEAD_TITLE-block TOP_TITLE -block BODY_TITLE TEMPLATE]

		# And the rest for each section
		set counter 0	
		# First the global section
		set counter [display_key_value [array get form_content global.*] $counter]
		clean_array [array get form_content global.*] form_content

		# Then the section with a type defined one
		# after the other
		set section_list [array get form_content *.type]
		set final_section_list ""
		foreach section_type $section_list {
			regsub {\.type$} $section_type {} new_section
			lappend final_section_list $new_section
		}
		foreach section $final_section_list {
			set counter [display_key_value [array get form_content "$section.*"] $counter]
			clean_array [array get form_content "$section.*"] form_content
		}
		# And the rest
		set counter [display_key_value [array get form_content "$section.*"] $counter]
		clean_array [array get form_content "$section.*"] form_content
		
		set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -block ALL_VALUE_ROWS TEMPLATE]		
		
		set final_html [atemt::atemt_subst -end TEMPLATE]
		#fas_debug "form::2fashtml content => $content" 
		return $final_html
	}

	# This procedure will translate a string in txt2ml format into html 
	# The args arguments, will be sent as is to the txt2ml command
	proc content2fashtml { current_env content args} {
		upvar $current_env fas_env
		global conf
		

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

		# and returning the result
		file delete $session_file_name
		return $result
	}

	proc get_title { filename } {
		fas_debug "form::get_title entering"
		# The title is the first line of the file
		set title ""
		array set temp_content ""
		if { ![catch {read_env $filename temp_content}] } {
			fas_debug "form::get_title ->  temp_content(global.title.[international::language])"
			set international_key "global.title.[international::language]"
			if { [info exists temp_content(global.title) ] } {
				set title $temp_content(global.title)
			}
			if { [info exists temp_content($international_key) ] } {
				set title $temp_content($international_key)
			}
		} 
		fas_debug "form::get_title found ->${title}<-"
		return $title
	}
	
	
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

		# ?????????? set edit_form::done 1
		# What I must do, is load a file,
		# Load and prepare a template
		# And send it back
		fas_depend::set_dependency $filename file

		# Due to the selectfile function, I think I need that
		# I am not so sure, but temporary_name is not used
		# for the cache name => I need to force it (this is not
		# normal, it should work ????)
		# If I change the name of the template with the select_file
		# it is not taken into account, if I do not do that
		#fas_depend::set_dependency 1 always
		array set temporary_array ""
		# loading the file
		if { 
			[ catch {
				read_env $filename temporary_array
			} ]
		} {
			fas_display_error "form::2edit_form - [translate "Could not load "] [rm_root $filename]" fas_env
		}
		# WARNING THE NEXT LINE MUST BE REMOVED ONCE THE FULL FORM EDITION IS COMPLETED
		set content "[array get temporary_array]"

		fas_debug_parray temporary_array "form::2edit_form - Temporary form array"

		# Getting the template
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env edit_form.form.template] } errStr] } {
			fas_display_error "form:2edit_form - [translate "Please define env variables"] edit_form.form.template<br>${errStr}" fas_env
		}

		fas_depend::set_dependency $template_name file

		if { [catch { atemt::read_file_template_or_cache "TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "form:2edit_form - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}
		# Current template
		fas_debug "form::2edit_form - current TEMPLATE - [atemt::atemt_set TEMPLATE]"
		# Preparing the variables
		atemt::atemt_set TITLE "[translate "Edit form for"] [rm_root $filename]"
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		set icons_url [fas_name_and_dir::get_icons_dir]
		set width 40
		set export_filename [rm_root $filename]
		set dir [rm_root [file dirname $filename]]
		# What is the name of the current form template (section) ?

		# Do I get it in coming back from a file selection dialog ?
		global _cgi_uservar
		fas_debug_parray _cgi_uservar "form::2edit_form - _cgi_uservar"
		if { [info exists _cgi_uservar(template_name)] } {
			set template_name $_cgi_uservar(template_name)
			# I get a template name in .tmpl, I must
			# have only the name (no directory) and .template as extension
			set template_name "[file rootname [file tail $template_name]].template"
			fas_debug "form::2edit_form : getting template_name from file selection"
			fas_debug "form::2edit_form : template_name => $template_name"
		} else {
			# I take it from the current file
			if { [info exists temporary_array(global.template)] } {
				set template_name $temporary_array(global.template)
				fas_debug "form::2edit_form : getting template_name from form file"
				fas_debug "form::2edit_form : template_name => $template_name"
			} else {
				set template_name ""
			}
		}
			
		# We substitute the variables
		set atemt::_atemt(TEMPLATE) [atemt::atemt_subst -block FORM -block TITLE -block FILENAME TEMPLATE]
		fas_debug "form::2edit_form - current TEMPLATE - [atemt::atemt_set TEMPLATE]<HR>$atemt::_atemt(TEMPLATE)<HR>"
		fas_debug "form::2edit_form - current TEMPLATE - [atemt::atemt_set TEMPLATE]"
		# Here there is filename and dir to substitute
		return [atemt::atemt_subst -end TEMPLATE]
	}

	# Get the list of all possible block type
	proc get_block_type_list { current_env } {
		upvar $current_env fas_env	

		set default_list [list unknown txt txt2ml html block file]

		global filetype_list
		foreach filetype $filetype_list {
			if { [llength [info commands ${filetype}::block_list]] > 0 } {
				# I can call it
				eval lappend default_list [${filetype}::block_list]
			}
		}
		fas_debug "form::get_block_type_list found => $default_list"
		return $default_list
	} 


	# Basic procedures to display and to get options for a block
	proc generic_display_options { current_env block_name options_list args } {
		fas_debug "form::generic_display_options -- entering"
		# Here I will ignore args
		# For text the options are simple :
		# width cols height
		array set temporary_array $options_list

		set PRINT_FLAG 0
		foreach argument $args {
			if { [string match $argument "-p*"] } {
				set PRINT_FLAG 1
			}
		}
		# I prepare the data - thanks to tcl power
	        # For the template, I need
	        # block_name, width, height, cols, checked_width, checked_height
	        # checked_cols
		foreach param [list width height cols] {
			set $param ""
			
			if { [info exists temporary_array(${block_name}.${param})] } {
				set ${param} $temporary_array(${block_name}.${param})
			    set checked_${param} "checked"
			} else {
			    set checked_${param} ""
			}
		}
		# Now I put the code in the template
		if $PRINT_FLAG {
			atemt::atemt_set CURRENT_DISPLAY_OPTIONS -bl [atemt::atemt_set GENERIC_PRINT_OPTIONS]
		} else {
			atemt::atemt_set CURRENT_DISPLAY_OPTIONS -bl [atemt::atemt_set GENERIC_DISPLAY_OPTIONS]
		}
		# And I do the substitution
		atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_subst -block CURRENT_DISPLAY_OPTIONS CURRENT_BLOCK]
		# That was it
	}

	proc generic_get_display_options { current_env block_name } {
		fas_debug "form::generic_get_display_options -- entering"
		array set temporary_array ""

		global _cgi_uservar
		if { [info exists _cgi_uservar(${block_name})] } {
			set temporary_array(${block_name}.type) $_cgi_uservar(${block_name})
		}

		foreach param [list width cols height] {
			if { [info exists _cgi_uservar(${block_name}.${param})] } {
				set temporary_array(${block_name}.${param}) $_cgi_uservar(${block_name}.${param})
			}
		}
		fas_debug "form::get_generic_display_options - block is $block_name - getting the following values => [array get $temporary_array]"
		return [array get $temporary_array]
	}

	# The dummy functions for txt, html and txt2ml
	proc html_display_options { current_env args } {
		upvar $current_env fas_env
		return [eval generic_display_options fas_env $args]
	}
	
	proc html_get_display_options { current_env args } {
		upvar $current_env fas_env
		return [eval generic_get_display_options fas_env $args]
	}
		
	proc txt_display_options { current_env args } {
		upvar $current_env fas_env
		return [eval generic_display_options fas_env $args]
	}
	
	proc txt_get_display_options { current_env args } {
		upvar $current_env fas_env
		return [eval generic_get_display_options fas_env $args]
	}
		
	proc txt2ml_display_options { current_env args } {
		upvar $current_env fas_env
		return [eval generic_display_options fas_env $args]
	}
	
	proc txt2ml_get_display_options { current_env args } {
		upvar $current_env fas_env
		return [eval generic_get_display_options fas_env $args]
	}

	proc block_display_options { current_env block_name options_list args } {
		# Here I will ignore args
		# For block the options are simple :
		#  the list of the blocks in the current_form
		fas_debug "form::block_display_options -- entering"
		array set temporary_array $options_list

		set BLOCK_NAME_FLAG 0
	        set block_block ""
		if { [info exists temporary_array(${block_name}.block) ] } {
			set BLOCK_NAME_FLAG 1
			set block_block $temporary_array(${block_name}.block)
		}
		# here args should be only one parameter :
		# the list of the blocks
		set block_list [lindex $args 0]

		# I create the list of block with a selection for block_block
		

		# Now I put the code in the template
		atemt::atemt_set CURRENT_DISPLAY_OPTIONS -bl [atemt::atemt_set BLOCK_DISPLAY_OPTIONS]
		
		# I go through the block_names
		foreach block_name $block_list {
		    if { $BLOCK_NAME_FLAG && [string match $block_name $block_block] } {
			atemt::atemt_set CURRENT_BLOCK_OPTION -bl [atemt::atemt_set BLOCK_OPTION_SELECTED]
		    } else {
			atemt::atemt_set CURRENT_BLOCK_OPTION -bl [atemt::atemt_set BLOCK_OPTION]
		    }
		    atemt::atemt_set CURRENT_DISPLAY_OPTIONS -bl [atemt::atemt_subst -insert -block CURRENT_BLOCK_OPTION CURRENT_DISPLAY_OPTIONS]
		}

		# And I do the substitution
		atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_subst -block CURRENT_DISPLAY_OPTIONS CURRENT_BLOCK]
		# That was it
	}

	# Display of options for a block of type FILE
	proc file_display_options { current_env block_name options_list args } {
		fas_debug "form::file_display_options -- entering for $block_name"
		# Here I will ignore args
		# For text the options are simple :
		# width cols heiht
		fas_debug "form::file_display_options options_list => $options_list"
		array set temporary_array $options_list

		set PRINT_FLAG 0
		foreach argument $args {
			if { [string match $argument "-p*"] } {
				set PRINT_FLAG 1
			}
		}
		# I just display the list of current options for the current block
		set long_param_list [array names temporary_array]
		atemt::atemt_set CURRENT_DISPLAY_OPTIONS -bl [atemt::atemt_set FILE_DISPLAY_OPTIONS]
		# And I display it
		fas_debug "form::file_display_options - long_param_list => $long_param_list"
		foreach long_param $long_param_list {
			set param $long_param
			fas_debug "form::file_display_options - processing param $long_param"
			regsub "^${block_name}\." $param "" param
			if { $param != "type" } {
				set content $temporary_array($long_param)
				fas_debug "form::file_display_options - param => $param , content => $content"
				if $PRINT_FLAG {
					atemt::atemt_set CURRENT_FILE_OPTION -bl [atemt::atemt_set FILE_PRINT_OPTION]
				} else {
					atemt::atemt_set CURRENT_FILE_OPTION -bl [atemt::atemt_set FILE_DISPLAY_OPTION]
				}
				atemt::atemt_set CURRENT_DISPLAY_OPTIONS -bl [atemt::atemt_subst -insert -block CURRENT_FILE_OPTION CURRENT_DISPLAY_OPTIONS]
			}
		}
		# And I do the substitution
		atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_subst -block CURRENT_DISPLAY_OPTIONS CURRENT_BLOCK]
	}
	
	proc unknown_display_options { current_env block_name options_list args } {
		fas_debug "form::unknown_display_options -- entering"
	}	

	proc 2edit.select_file { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
	        global _cgi_uservar

		# so I am in the file selection dialog, I must get a file name
		# First I unset template_name.fs.x
		unset _cgi_uservar(template_name.fs.x)
		unset _cgi_uservar(template_name.fs.y)
		# Now I get an existing filename if there is one
		if { [info exists _cgi_uservar(template_name)] } {
			set template_name $_cgi_uservar(template_name)
		        # I suppress it, no need to store it in
		        # the session variable
                        unset _cgi_uservar(template_name)
		}

		# template_name is really a naked name : no extension, no directory, 
		# nothing. I must recreate a real template_name
		set real_template_name [fas_name_and_dir::get_template_name fas_env $template_name] 
		# Now I need a directory
		if { [file isdirectory $real_template_name] } {
			# nothing to do
			set template_dir $template_name
		} else {
			set template_dir [file dirname $real_template_name]
		}

		# Now I store what needs to be stored in a session variable
		# I need to jump to edit_form when coming back so I force
		# the action
		set _cgi_uservar(action) "edit_form"
		fas_session::setsession _cgi_uservar [array get _cgi_uservar]
		fas_session::setsession comefrom "edit_form"
		fas_session::setsession filename "[rm_root $filename]"
		fas_session::setsession selectsection "template_name"

		# And now I call a way to select a file.
		# Basically a dir to display, with a special tag file list for having a
		# selection checkbox.
		unset _cgi_uservar
		set _cgi_uservar(action) edit_form
		set _cgi_uservar(display) "shortname,title,select"
		set _cgi_uservar(extension_list) "*.tmpl"
		set _cgi_uservar(form) "1"
		set _cgi_uservar(noadd) "1"
		# HUM, HUM, HUM, the next one is hot
		# It is recursive. I must preserve treedir.url_start
		# within the call. Then I need to escape the special
		# chars. So I try (I am not sure that it will work).
		set _cgi_uservar(treedir.url_start) "?action=show_select_file&file="
		global conf
		display_file dir $template_dir fas_env conf
		fas_session::write_session
		fas_exit
	}

        # print a block : name, type and then the associated options 
        # BLOCK_STATE may be BLOCK, UNKNOW_TEMPLATE_BLOCK, UNKNOWN_FORM_BLOCK
        proc print_block { current_env form_array block_name current_block_type block_type_list template_block_list BLOCK_STATE } {
            upvar $current_env fas_env
            upvar $form_array temporary_array

	    set DISPLAY_OPTION_FLAG 0

            global FAS_VIEW_CGI

	    # I need to know if there is a no_edit variable
	    # and to show it in a ${block_name}.no_edit checkedbox
            if { [info exists temporary_array(${block_name}.no_edit)] } {
	    	set checked_no_edit checked
		set no_edit 1
	    } else {
	    	set checked_no_edit ""
		set no_edit 0
	    }

	    # I add the block as a known one
	    atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_set "${BLOCK_STATE}.PRINT" ]

	    # I use current_block_type to display the block_type
	    # And I create a translated_current_block_type
	    set translated_block_type [translate $current_block_type]
	    atemt::atemt_set CURRENT_OPTION -bl [atemt::atemt_set PRINT_BLOCK_TYPE]
	    atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_subst -insert -block CURRENT_OPTION CURRENT_BLOCK]

	    # And I may have other options to display hereunder
	    # The possible block_type html txt block txt2ml file
	    ${current_block_type}_print_options fas_env ${block_name} [array get temporary_array "${block_name}.*"] $template_block_list
	    atemt::atemt_set TEMPLATE -bl [atemt::atemt_subst -insert -block CURRENT_BLOCK TEMPLATE]

        }

        # display a block : name, type and then the associated options 
        # (if the option -do is used)
	# If the -print option is used, it is tryed to only display and not
	# to propose for modifying the values
        # BLOCK_STATE may be BLOCK, UNKNOW_TEMPLATE_BLOCK, UNKNOWN_FORM_BLOCK
        proc display_block { current_env form_array block_name current_block_type block_type_list template_block_list BLOCK_STATE args } {
            upvar $current_env fas_env
            upvar $form_array temporary_array

	    set DISPLAY_OPTION_FLAG 0
	    foreach arg $args {
		switch -exact -- $arg {
		    "-do" {
			set DISPLAY_OPTION_FLAG 1
		    }
		    "-print" {
		    	set PRINT_OPTION_FLAG 1
		    }
                }
            }

            global FAS_VIEW_CGI

	    # I need to know if there is a no_edit variable
	    # and to show it in a ${block_name}.no_edit checkedbox
            if { [info exists temporary_array(${block_name}.no_edit)] } {
	    	set checked_no_edit checked
		set no_edit 1
	    } else {
	    	set checked_no_edit ""
		set no_edit 0
	    }

	    # I add the block as a known one
	    atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_set ${BLOCK_STATE} ]

	    # I prepare the options
	    foreach block_type $block_type_list {
		fas_debug "form::display_block - processing $block_type"
		if { $block_type == $current_block_type } {
		    atemt::atemt_set CURRENT_OPTION -bl [atemt::atemt_set OPTION_SELECTED]
		} else {
		    atemt::atemt_set CURRENT_OPTION -bl [atemt::atemt_set OPTION]
		}
		set nice_block_type $block_type
		atemt::atemt_set CURRENT_BLOCK -bl [atemt::atemt_subst -insert -block CURRENT_OPTION CURRENT_BLOCK]
	    }
	    # And I may have other options to display hereunder
	    # The possible block_type html txt block txt2ml file
	    #fas_debug "form::display_block -- ${current_block_type}_display_options fas_env ${block_name} [array get temporary_array "${block_name}.*"]  $template_block_list"
	    if $DISPLAY_OPTION_FLAG {
		${current_block_type}_display_options fas_env ${block_name} [array get temporary_array "${block_name}.*"] $template_block_list
	    }
	    atemt::atemt_set TEMPLATE -bl [atemt::atemt_subst -insert -block CURRENT_BLOCK TEMPLATE]

        }

	proc 2edit.present_block { current_env filename form_template_name } {
	    	upvar $current_env fas_env
		global FAS_VIEW_CGI

		# I come from the template selection screen
		# I show the list of the top block with the types
		# So I need to read the template, get the list
		# of the block, look if there are in the current
		# form, if they have a value or not
		# and then show the different values associated

		# Read the template
		if { [catch { set template_filename [fas_name_and_dir::get_template_name fas_env $form_template_name] } errStr] } {
			fas_display_error "form::2edit.present_block - [translate "Could not find the following template"] $form_template_name<br>${errStr}" fas_env
		}
		# setting a dependency on the template
		fas_depend::set_dependency $template_filename file
		# reading the template
		if { [catch { atemt::read_file_template_or_cache "TEMPLATE" "$template_filename" } errStr ] } {
			fas_display_error "form::2edit.present_block - [translate "Problem while opening template "] ${template_filename}<br>${errStr}" fas_env -f $filename
		}
		# Getting the top block for this template :
		set template_block_list ""
		#fas_debug "form::2edit.present_block - getting the TEMPLATE => [atemt::atemt_set TEMPLATE]"
		foreach block_list [atemt::atemt_set TEMPLATE] {
			set type [lindex $block_list 0]
			if { $type == "block" } {
				# OK it is a block
				# I take the name
				lappend template_block_list [lindex $block_list 1]
			}
		}
		set template_block_list [string tolower $template_block_list]

		fas_debug "form::2edit.present_block - detected following block list => $template_block_list"

		# So now, I must reload a real template and prepare the display
		atemt::init
		# Read the template
		if { [catch { set template_filename [fas_name_and_dir::get_template_name fas_env edit_form.block_type.form.template ] } errStr] } {
			fas_display_error "form::2edit.present_block - [translate "Could not find the following template"] edit_form.block_type.form.template<br>${errStr}" fas_env
		}
		# setting a dependency on the template
		fas_depend::set_dependency $template_filename file
		# reading the template
		if { [catch { atemt::read_file_template_or_cache "TEMPLATE" "$template_filename" } errStr ] } {
			fas_display_error "form::2edit.present_block - [translate "Problem while opening template "] ${template_filename}<br>${errStr}" fas_env -f $filename
		}
		#fas_debug "form::2edit.present_block - _atemt(TEMPLATE) on start => [atemt::atemt_set TEMPLATE]" 

		# I must read the content of the form first 
		array set temporary_array ""
		# loading the file
		if { [ catch { read_env $filename temporary_array } ] } {
			fas_display_error "form::2edit.present_block - [translate "Could not load "] [rm_root $filename]" fas_env
		}


		# I need to have the list of all possible block type
		# To do that I call a specialised function
		set block_type_list [get_block_type_list fas_env]

		# First I go through all the blocks. 
		foreach block_name [string tolower $template_block_list] {
			# Is it defined in the form values ?
			if { [info exists temporary_array(${block_name}.type)] } {
				# The block is known
				fas_debug "form::2edit.present_block - block display - found ${block_name}.type"
				set current_block_type $temporary_array(${block_name}.type)
			        display_block fas_env temporary_array $block_name $temporary_array(${block_name}.type) $block_type_list $template_block_list BLOCK -do

			} else {
				# the block is not in the template
				# I add the block as an unknown one
                                display_block fas_env temporary_array $block_name unknown $block_type_list $template_block_list UNKNOWN_TEMPLATE_BLOCK
			}

			#fas_debug "form::2edit.present_block - TEMPLATE [atemt::atemt_set TEMPLATE]"
		}

		# Now I need to find the blocks that are in temporary array
		# and that are not in TEMPLATE
		set temporary_array_blocks [array names temporary_array *.type]
		foreach temporary_block $temporary_array_blocks {
		    set real_temporary_block_name ""
		    if { [regexp {^(.*).type} $temporary_block match real_temporary_block_name ] } {
			if { [lsearch $template_block_list $real_temporary_block_name] < 0 } { 
			    # So the block in the form file but not in the template
			    set block_name $real_temporary_block_name
			    # I need to display it
			    # I should make a function of the code hereunder
			    # The block is known
			    fas_debug "form::2edit.present_block - block display - found ${block_name}.type - unknown in template"
		            set current_block_type $temporary_array(${block_name}.type)

			    # I add the block as a known one
                            display_block fas_env temporary_array $block_name $current_block_type $block_type_list $template_block_list UNKNOWN_FORM_BLOCK -do
		         }
		    }
		}
		set export_filename [rm_root $filename]
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		set icons_url [fas_name_and_dir::get_icons_dir]
		atemt::atemt_set TEMPLATE -bl [atemt::atemt_subst -block TOP_FORM -block BOTTOM_FORM TEMPLATE]
		#fas_debug "form::2edit.present_block - _atemt(TEMPLATE) before the end => [atemt::atemt_set TEMPLATE]" 
		set final_html [atemt::atemt_subst -end TEMPLATE]
		#fas_debug "form::2edit.present_block - TEMPLATE => $final_html"
		return $final_html
	}


	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		# Here there is a special case :
		# I may come here because of a click on a file selection button.
		# So I must detect that, then jump to the action corresponding, having stored everything.

		# The next code chunk is an adaptation of comp::2edit where I used for
		# the first time select_file
		global _cgi_uservar

		if { [info exists _cgi_uservar(template_name.fs.x)] } {
		        2edit.select_file fas_env $filename
		}

		# So I may come from the template name selection
		if { ![catch {set form_template_name [fas_get_value template_name]} ] } {
			if { ![catch {set sub_action [fas_get_value sub_action] } ] } {
				# I am in the validate phase
				2edit.validate_block fas_env $filename $form_template_name
			} else {
				# I am right now editing the values
		        	2edit.present_block fas_env $filename $form_template_name
			}
		}

		# I may be in a refresh of present_block
		# It is the same code but instead of taking the informations
		# from temporary_array, I take them from _cgi_uservar
		# There is also a difference concerning the way we know if
		# an option is selected or not.
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
		set real_filename [fas_name_and_dir::get_real_filename txt $filename env]
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file
		return "[not_binary::content fas_env $filename txt]"
	}
}
