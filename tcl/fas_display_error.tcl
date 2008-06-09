set BUS_GESTION_ERROR 0
set FATAL_ERROR 0
set ORDER_ERROR_CODE 1056

# This procedure is used for displaying an error in case of problem.
# The problem is the following : in a real site, such an error display
# should be as nice as possible (with the look of the site and so on).
# But on the other side, such a procedure must be as simple as possible.
# If you display an error, you do not want to have an error while displaying 
# the error message. So some simple solution must be found and used.
proc fas_display_error { message current_env args } {
	# BUS_GESTION_ERROR is a flag indicating
	# that we are dealing with an error
	# within a journal. Then, the journal
	# must continue (display the next page)
	# and not an error
	global BUS_GESTION_ERROR
	set state parse_args
	upvar $current_env fas_env

	fas_debug "fas_display.tcl::fas_display_error :: message - $message"
	# Sometimes I have errors, and it generate errors, that ...
	# In those case at the 3rd loop, I want to output something
	global ERROR_LOOP
	incr ERROR_LOOP

	fas_debug "fas_display_error - entering - $message - current_env - $args"
	fas_debug "fas_display_error - ERROR_LOOP = $ERROR_LOOP"
	if { [catch { set filename [add_root [fas_name_and_dir::get_root_dir]] } ] } {
		set filename  [add_root "any"]
	}

	global conf
	set FLAG_FILENAME 0
	set FLAG_ENV 0
	global FATAL_ERROR
	foreach arg $args {
		switch -exact -- $state {
			parse_args {
				switch -glob -- $arg {
					-f* {
						set state filename
						set FLAG_FILENAME 1
					}
				}
			}
			filename {
				set filename $arg
				set state parse_args
			}
		}
	}
        if { ($BUS_GESTION_ERROR == "0") || ($FATAL_ERROR == "1")} {
		# If I am within a comp document. I want the error in the document.
		# I try to generate an error for that
		global IN_COMP
		if { $IN_COMP } {
			error "<h1>[translate "The following error just occured"]</h1> : <b>$message</b><P>"
		}
		set error_title "[translate "Error :"] $message"
		global FAS_VIEW_CGI
		set error_content "<center><h1>[translate "An error just occured"] :</h1></center>\n		<b>$message</b><br>\n<p style=\"width:100%;text-align:center;\"><a href=\"${FAS_VIEW_CGI}?file=/any\">Back to home page</a></p>"

		if { [is_debug] } {
			# I try to use info level
			# I do not need to show the fas_display_error call hence the
			# expr info level - 1
			append error_content "<font color=\"red\">[translate "******** Calling stack at this level : *****"]\n		<PRE>"
			for { set i [expr [info level] - 1]; set full_message "" } { $i > 0 } { incr i -1 } {
				for { set tab ""; set j 1 } { $j < $i } {incr j; set tab "    $tab"} { }
				append error_content "${tab}+->[info level $i]<BR>"
			}
			append error_content "</PRE>\n<pre>##################################\n${::DEBUG_STRING}\n</pre>"
			if { $::DEBUG_SHOW } {
				if { [info exists ::DEBUG_FILENAME] } { 
				regsub -all {[^01-9\-]} $::DEBUG_FILENAME {} deb_id
				append error_content "&nbsp;<font size=\"-1\"><a href=\"$::FAS_VIEW_URL?file=[rm_root ${filename}]&action=show_debug_file&debug_identifier=${deb_id}\">Debug file</a></font>"
				}
			}
			if { $::MAIN_LOG && $::MAIN_LOG_SHOW } {
				regsub -all {[^01-9\-]} $::MAIN_LOG_FILENAME {} deb_id
				append error_content "&nbsp;<font size=\"-1\"><a href=\"$::FAS_VIEW_URL?file=[rm_root ${filename}]&action=show_debug_file&debug_identifier=${deb_id}&mainlog=1\">Main log file</a></font><br>"
			}
		}

		# I throw out the error directly, that's it and that's all
		# I have to many displays with error in the error and then
		# a false error message
		#if { ( $ERROR_LOOP > 3 ) || [catch { display_content htmf $error_content env conf; set ERROR_LOOP 0 } error_error ] } {
		# }
		if {  $ERROR_LOOP > 1  } {
			# there was an error I must use a simpler way to display things
			if { [catch {not_binary::content_display fashtml $error_content} ] } {
                                # Still to complex
                                puts $error_content
                        }
			set ERROR_LOOP 0
			# Exit is a very bad idea, as it ends up tclhttpd
			# I try to replace that
			end_debug
			fas_exit
		} else {
			# I am not in a composite document. Then I display the error
			# I will try to use the current environment and look for improving the look
			# I load the standard template, and replace content with the error
			if { [catch {
				set template_name [fas_name_and_dir::get_template_name fas_env standard.template] 
				atemt::read_file_template_or_cache "TEMPLATE" $template_name
				set icons_url [fas_name_and_dir::get_icons_dir]
				set export_filename [rm_root2 $filename]
				set dir [rm_root2 [file dirname $filename]]
				set from ""
				atemt::atemt_set CONTENT "$error_content"
				atemt::atemt_set TITLE "$error_title"
				fas_debug "fas_display_error::fas_display_error - CONTENT and TITLE set"
				# -vn is for having no variable substitions in the strings !!!!
				atemt::atemt_set TEMPLATE -bl [atemt::atemt_subst -vn -block TITLE -block CONTENT TEMPLATE]
				fas_debug "fas_display_error::fas_display_error - subst of TEMPLATE" 

				#fas_debug "fas_display_error::fas_display_error ::atemt::_atemt(TEMPLATE) - $::atemt::_atemt(TEMPLATE)"
				set content [atemt::atemt_subst_end TEMPLATE]
				#fas_debug "fas_display_error::fas_display_error - check fashtml::content2html" 
				if { [llength [info commands fashtml::content2html]] == 0 } {
					global FAS_PROG_ROOT
					# Optimisation thanks to :
					# http://aspn.activestate.com/ASPN/Tcl/TclConferencePapers2002/
					#  Tcl2002papers/kenny-bytecode/paperKBK.html#1001027
					namespace eval :: source ${FAS_PROG_ROOT}/mimeprocs/fashtml.tcl
				}
				#fas_debug "fas_display_error::fas_display_error - fashtml::content2htmf on $content $filename"
				set final_content [fashtml::content2htmf fas_env $content $filename]
				fas_debug "fas_display_error::fas_display_error - subst end on TEMPLATE - content =>>>> $content"

				not_binary::content_display fashtml $final_content
			} catch_error ] } {
				# I ask for the same message of error, and not to take into account
				# the previous error
				append message $catch_error
				eval fas_display_error "\{$message\}" fas_env $args
			}
			end_debug
			fas_exit
		}
		#fas_debug "fas_display.tcl::fas_display_error -> $error_content"

	} else {
		# This is a special case : an error in a journal display
		# Then I need to just return from there
 		fas_debug "fas_display.tcl::fas_display_error :: BUS :: message - $message"

		# Error management
 		if [catch {fas_session::setsession order_current_action } action_error ] {
 			# to see: if error but no msg, what to do ??
 			# jump first section of main or cond file ??
 			set action_error none
 		}
	    
		fas_debug "error: $action_error"
 		fas_session::setsession order_error $action_error
 		fas_session::setsession order_current_action "none"
		global ORDER_ERROR_CODE
		return -code error $ORDER_ERROR_CODE

 	}
}
