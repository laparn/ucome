# extension for txt
set conf(extension.css) css

lappend filetype_list css

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval css {
	# What command to use to translate the txt in txt2ml
	# The -re option allows to convert relative links in absolute one
	# Finally, I put this function in htmf, then it is not useful in
	# the command line here.

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		# This is the default answer
		set result ""
		# Now there may be other cases
		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "css::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		return ""
		#error 1
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list ]
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

	proc mimetype { } {
		return "text/css"
	}



	proc get_title { filename } {
		return [::not_binary::get_title $filename]
		fas_debug "css::get_title found ->$title<-"
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
		#set icons_url [fas_get_value icons_url -default "fas:/icons"]
		set icons_url [fas_name_and_dir::get_icons_dir]
		set export_filename [rm_root $filename]
		set dir [rm_root [file dirname $filename]]
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
			set _cgi_uservar(message) "$error_string"
		} else {
			set _cgi_uservar(message) "$message"
		}
	
		# And now asking for the display of the directory
		set dir_name [file dirname $filename]
		#set _cgi_uservar(edit_dir) 1
		#unset _cgi_uservar(action)
		set _cgi_uservar(action) "edit_form"
		global conf
		#puts "Ready to display the directory"
		display_file dir $dir_name fas_env conf
		fas_exit
	}
		
	proc content_display { current_env content } {
		global conf
		upvar $current_env env

		if { ![info exists conf(tclhttpd)] && ![info exists conf(tclrivet)] } {
			cgi_http_head {
				cgi_content_type [css::mimetype]
				fas_session::export_session
			}
			# I added the cgi_body for the debug getting cookies and variables
			# If I am displaying a part of a composite page, I do not want the debug
			# Everything will be displayed at the end
			puts "$content"
		} elseif { [info exists conf(tclrivet)] } {
			headers type [mimetype]
			fas_session::export_session
			puts "$content"
		} else {
			# I am in the tclhttpd case, I do something
			global conf
			set sock $conf(sock)
			Httpd_ReturnData $sock [css::mimetype] "$content"
		}
	}
		
	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		global FAS_VIEW_URL
		if { [catch {open $filename} css_id] } {
			fas_debug "css::display - error at display"
		} else {
			set css_content [read $css_id]
			close $css_id
			set final_css_content [string map [list "fas:" "${FAS_VIEW_URL}?file="] $css_content]
			# Before websh - test
			#content_display fas_env $final_css_content
			::not_binary::content_display css $final_css_content
		 }
		#return "[not_binary::display fas_env $filename css]"
	}
	proc content { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::content fas_env $filename css]"
	
	}
}
