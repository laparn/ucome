set ::conf(extension.xml) xml
lappend filetype_list xml

namespace eval xml {
	global ::FAS_PROG_ROOT
	# Here I give values that are adapted to xsltproc and docbook on Debian
	# I suppose that it is different on other distribution
	# Please adapt it
	set local_conf(xml.convert) "/usr/bin/xsltproc -xinclude --stringparam section.autolabel 1 --stringparam section.label.includes.component.label 1 "
	set local_conf(xml.html_docbook_stylesheet) "/usr/share/xml/docbook/stylesheet/nwalsh/html/docbook.xsl"

	# Documentation
	set ucome_doc {Basic processing of xml files. At first, I will only use it for dookbook. However, you may tune it for other xml type.
I get the title in looking at the 50 first lines and looking for <title>xxx</title>.
Concerning the configuration values defined in xml.tcl, I give values that are adapted to xsltproc and docbook on Debian. I suppose that it is different on other distribution. Please adapt it.}

	global ::DEBUG_PROCEDURES
	eval $::DEBUG_PROCEDURES

	global ::STANDARD_PROCEDURES
	eval $::STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		upvar $current_env fas_env
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
					return ""
				}
				nomenu {
					set result fashtml
				}
				ori {
					return ""
				}
				txt4index {
					set result txt4index
				}
			}
		}
		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "tmpl" ) && ( $new_type_option == "notmpl" ) } {
			set result fashtml
		}
		fas_debug "xml::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list comp fashtml]
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
		#lappend env_list [list "xml.xxx" "Blablabla" user]
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new xml with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf args } {
		fas_debug "xml::new - _env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		eval fashtml::new fas_env fas_conf $args
	}

	proc mimetype { } {
		return "application/xml"
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
	# This procedure will translate a txt into html 

	# The dependencies are the following :
	#  - eventually $env(perso.tcl), $env(style)
	proc 2fashtml { current_env filename args } {
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename xml $filename fas_env]

		# I need the following informations
		# perso and style files, 
		# cachetmpl directory

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		variable local_conf
		fas_debug "xml::2fashtml :|$local_conf(xml.convert) $local_conf(xml.html_docbook_stylesheet) $real_filename" 

		set content ""
		if { [catch {
			set fid [open "|$local_conf(xml.convert) $local_conf(xml.html_docbook_stylesheet) $real_filename"]
			set content [read $fid] 
			close $fid
		} error ] } {
			set content "$error - while executing |$local_conf(xml.convert) $local_conf(xml.html_docbook_stylesheet) $real_filename"
		}

		return $content
	}
        # JV, 23072004
	proc 2title { current_env filename } {
	        upvar $current_env fas_env
	        fas_debug "xml::2title [get_title $filename]"
	        if { [info exists fas_env(title.title)] } {
			set title "$fas_env(title.title)"
		} else {
		        fas_debug "xml::get_title entering"
		        # The title is the first line of the file
			set title [get_title $filename]
			fas_debug "xml::2title found ->$title<-"
		}
		regsub -all {\&} $title {\&amp;} title
		return $title
	}

	proc get_title { filename } {
		set title ""
		if { ![catch {open $filename} fid] } {
			set not_find_title 1
			set line_number 0
			while { $not_find_title && ![eof $fid] && $line_number < 50 } {
				set line [gets $fid]
				if { [regexp -nocase {< *title *>(.*?)</title *>} $line match title] } {
					set not_find_title 0
				}
				incr line_number
			}
			close $fid
		}
		return $title
	}
	
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		global FAS_VIEW_CGI

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

	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename txt]"
	}

	proc 2txt4index { current_env filename } {
		upvar $current_env fas_env
		set real_filename [fas_name_and_dir::get_real_filename txt $filename fas_env]
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file
		# I am going to suppress all tags
		set content ""
		if { [catch {set fid [open $real_filename] } ] } {
			error "Problem while opening [rm_root2 $real_filename]"
		} else {
			set content [read $fid]
			close $fid
		}
		regsub -all {<[^>]*?>} $content {} content
		return $content
	}
}
