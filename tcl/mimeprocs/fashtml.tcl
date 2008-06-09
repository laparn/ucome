# Due to a conflict with tcllib html module I rename
# html into fashtml. Ouinnnnnnnnnnnnnn.
#set conf(newtype.html) pdf
set conf(extension.fashtm) fashtml
set conf(extension.fashtml) fashtml
#set conf(mod_rewrite) 1
lappend filetype_list fashtml

namespace eval fashtml {
	# Well, if the software change, it may change
	set local_conf(fas_view_url) "?file="
	#set local_conf(html.lynx) /usr/bin/fas_lynx
	set local_conf(html.lynx) "lynx -dump "

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		fas_fastdebug {fashtml::new_type $filename}

	 	# When a html is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) htmf
		# This is the default answer
		set result htmf
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "fashtml::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		if { ![catch {set target [fas_get_value target -noe]}] } {
			switch -exact -- $target {
				fashtml {
					# Here I must directly finish
					# then I throw an error that should
					# be catched
					#error 1
					return ""
				}
				ori {
					set result txt
					#error 1
					return ""
				}
				pdf {
					global conf
					if { [info exists conf(tclhttpd)] } {
						global FAS_VIEW_URL
						global FAS_VIEW_URL2
						set FAS_VIEW_URL $FAS_VIEW_URL2
					}
				}
				# begin modif Xav
				#rrooll -
				#rool {
				#	fas_debug_parray fas_env "fashtml::new_type fas_env before down_stage_env with rool"
				#	down_stage_env fas_env "rrooll.cgi_uservar."
				#	fas_debug_parray fas_env "fashtml::new_type fas_env after down_stage_env with rool"
				#	return "comp"
				#}
				# end modif Xav
				#rrooll1 -
				#rool1 {
				#	fas_debug_parray fas_env "fashtml::new_type fas_env before down_stage_env with rrool1"
				#	down_stage_env fas_env "rrooll1.cgi_uservar."
				#	fas_debug_parray fas_env "fashtml::new_type fas_env after down_stage_env with rrool1"
				#	return "comp"
				#}
				#rrooll2 -
				#rool2 {
				#	fas_debug_parray fas_env "fashtml::new_type fas_env before down_stage_env with rrool2"
				#	down_stage_env fas_env "rrooll2.cgi_uservar."
				#	fas_debug_parray fas_env "fashtml::new_type fas_env after down_stage_env with rrool2"
				#	return "comp"
				#}
				#rrooll3 -
				#rool3 {
				#	fas_debug_parray fas_env "fashtml::new_type fas_env before down_stage_env with rrool3"
				#	down_stage_env fas_env "rrooll3.cgi_uservar."
				#	fas_debug_parray fas_env "fashtml::new_type fas_env after down_stage_env with rrool3"
				#	return "comp"
				#}
			}
		}
		 global IN_COMP
		# If we are in a comp, I send back directly the content
		# No need to go to htmf. It will be done after.
		if { $IN_COMP } {
			#error 1
			return ""
		}
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list htmf]
	}

	# Return the list of environment variables that are important
	# If this function is not defined, then no env variables are important
	proc env { args } {
		set env_list ""
		#lappend env_list [list "fashtml.fas_view_url" [list en "Url used for modifying a relative url (img, link or input) into an absolute link. This is useful when transforming into htmf."] [list fr "Url utilisé pour modifier les liens relatifs en liens absolus. Ceci est utile lors des transformations en htmf."]]
		return $env_list
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 1
	}

	# Procedure for creating a new file txt, tmpl or html :
	# First I create the a file, then I call edit on it, 
	# At the end I exit
	proc new { current_env current_conf dirname filename filetype ON_EXTENSION_FLAG } {
		fas_debug "fashtml::new - $dirname $filename $filetype $ON_EXTENSION_FLAG current_env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		set new::done 1
		
		# What is the real file to create
		set full_filename [file join $dirname $filename]
		fas_debug "fashtml::new - creating file $full_filename"

		# Trying to open it for writing
		if [ catch {set fid [open $full_filename w]}] {
			# There was an error, I display it
			fas_display_error "[translate "Impossible to open "] $full_filename [translate " for writing"]" fas_env -f $dirname
		} else { 
			close $fid
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

			display_file $filetype $full_filename fas_env fas_conf
			# And I exit as something will be displayed
			fas_exit
		}
	}

	proc mimetype { } {
		return "text/html"
	}

	proc ucome_doc { } {
		set content {A pure html file with all menu, navigation widgets, sections, ... Ready to display, except that there may be relative links in it (in img or links) that would be broken. Then it must be transformed into htmf (f for final).}
		return $content
	}

	proc 2pdf { current_env args } {
		upvar $current_env env
	
		return [eval htmf::pdf env $args]	
	}

	proc content2pdf { current_env args } {
		upvar $current_env env
	
		return [eval htmf::content_pdf env $args]	
	}

	proc 2htmf { current_env filename} {
		upvar $current_env env
		global conf

		fas_debug "#####2htmf - entering"
		# I am just going to track content with relative links
		# and change it into absolute links and img names
		# So I must find A HREF tags and IMG SRC tags
		# then look if there is : inside => I do not touch
		# starting with / => I do not touch
		# It is a relative link, I add the directory name at start +
		# /cgi-bin/fas_view2.cgi?file= just before it

		set real_filename [fas_name_and_dir::get_real_filename fashtml $filename env]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		# Now I read the file
		set fid [open $real_filename]
		set content [read $fid]
		close $fid
		return [content2htmf env $content $filename]
	}

	# content2htmf
	# If there is a third argument it is filename
	# required for changing relative links in absolute one
	proc content2htmf { current_env content args } {
		upvar $current_env env
		global conf

		fas_debug "fashtml::content2htmf - entering"
		fas_debug "$content"
		# Was a filename given ?
		set filename [fas_name_and_dir::get_root_dir]
		#set filename $env(root_directory)
		if { [llength $args] > 0 } {
			set filename [lindex $args 0]
		}

		# I am just going to track content with relative links
		# and change it into absolute links and img names
		# So I must find A HREF tags and IMG SRC tags
		# then look if there is : inside => I do not touch
		# starting with / => I do not touch
		# It is a relative link, I add the directory name at start +
		# /cgi-bin/fas_view2.cgi?file= just before it

		# we build couple of ( tag to match , url to match in the matched tag )
		# modif Xav : added some support for javascript <script src="xxx.js">
		# 
		set list_tag_url [list {<[Ii][Mm][Gg][^>]+?>} {(.*[Ss][Rr][Cc]=["'])([^"' >]+)(["'].*)} \
				      {<[Aa][^>]+?>} {(.*[Hh][Rr][Ee][Ff]=["'])([^ #>]+)(["'][ >].*)} \
				      {<[Aa][^>]+?>} {(.*[Hh][Rr][Ee][Ff]=["'])([^">]+)(["'] *[>].*)} \
				      {<[Ll][Ii][Nn][Kk][^>]+?>} {(.*[Hh][Rr][Ee][Ff]=["'])([^ #>]+)(["'][^>]+?>.*)} \
				      {<[Ii][Nn][Pp][Uu][Tt][^>]+?>} {(.*[Ss][Rr][Cc]=["'])([^ >]+)(["'][ >].*)} \
				      {<[Ff][Rr][Aa][Mm][Ee][^>]+?>} {(.*[Ss][Rr][Cc]=["'])([^ >]+)(["'][ >].*)} \
					  {<[Ss][Cc][Rr][Ii][Pp][Tt][^>]+?>} {(.*[Ss][Rr][Cc]=["'])([^ >]+)(["'][ >].*)} \
				      {<[Bb][Oo][Dd][Yy][^>]+?>} {(.*[Bb][Aa][Cc][Kk][Gg][Rr][Oo][Uu][Nn][Dd]=["'])([^ >]+)(["'][ >].*)} \
					  {< *[dD][iI][Vv] +[^>]+?>} {(.*background-image: *url\()([^)]+)(\);[^"]+".*)} \
					  {< *[eE][Mm][Bb][eE][Dd][^>]+?>} {(.*[Ss][Rr][Cc]=["'])([^ >]+)(["'].*)} \
					  {< *[dD][iI][Vv] +[sS][Tt][yY][Ll][eE][^>]+?>} {(.*background-image: *url\()([^)]+)(\);[^"]+".*)} \
					  {background-image:[^)]+\);} {(.*url\()([^)]+)(\);.*)} \
				      {< *[Pp][Aa][Rr][Aa][Mm][^>]+?>} {(.*[Vv][Aa][Ll][Uu][Ee] *= *["'])(fas:[^ >]+)(["'].*)} \
					  {([\t ]*[Xx][Ii][Nn][Cc][Ll][Uu][Dd][Ee]\(["'])([^ >]+)(["']\)[ ]*;[\t ]*)} \
					  {([\t ]*[Xx][Ii][Nn][Cc][Ll][Uu][Dd][Ee]\(["'])([^ >]+)(["']\)[ ]*;[\t ]*)} \
				     ]

		fas_debug "fashtml::content2htmf - processing tags"
		foreach { tag url } $list_tag_url {
			# begin is a cursor on the original string
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
					if { [info exists conf(mod_rewrite)] } {
							fas_debug "fashtml::content2htmf - conf(mod_rewrite) exists"
					        #fas_fastdebug {fashtml::2htmf - $conf(mod_rewrite)}
					        if { $conf(mod_rewrite) } {
								# begin modif Xav
								fas_debug "fashtml::content2htmf - using mod_rewrite"
								if [catch { set urlstring [string range $content $begin_tag $end_tag] }] {
									fas_debug "fashtml::content2htmf - error with url string"
								} else {
									fas_debug "fashtml::content2htmf - url string ok :  \"$urlstring\""
						        	set result "$result[to_right_url_mod_rewrite $urlstring $url $filename]"
								}
								#end modif Xav
					        } else {
								# begin modif Xav
								fas_debug "fashtml::content2htmf - using to_right_url"
								if [catch { set urlstring [string range $content $begin_tag $end_tag] }] {
									fas_debug "fashtml::content2htmf - error with url string"
								} else {
									fas_debug "fashtml::content2htmf - url string ok :  \"$urlstring\""
									set result "$result[to_right_url $urlstring $url $filename]"
								}
								# end modif Xav
					        }
					} else {
						# begin modif Xav
						fas_debug "fashtml::content2htmf - conf(mod_rewrite) doesn't exist"
						if [catch { set urlstring [string range $content $begin_tag $end_tag] }] {
							fas_debug "fashtml::content2htmf - error with url string"
						} else {
							fas_debug "fashtml::content2htmf - url string ok : \"$urlstring\""
							set result "$result[to_right_url $urlstring $url $filename]"
						}
						#end modif Xav
					}
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

		# Now if necessary adding a link to the debug file
		if { $::DEBUG && $::DEBUG_SHOW } {
			set tag ""
			set end ""
			if { [regexp {^(.*)(< */[Bb][Oo][Dd][Yy] *>)(.*)$} $content match result tag end] } {
				set content $result
			}
			if { [info exists ::DEBUG_FILENAME] } {
			regsub -all {[^01-9\-]} $::DEBUG_FILENAME {} deb_id
			append content "&nbsp;<font size=\"-1\"><a href=\"$::FAS_VIEW_URL?file=[rm_root ${filename}]&action=show_debug_file&debug_identifier=${deb_id}\">Debug file</a></font>${tag}${end}"
			} else {
				append content "${tag}${end}"
			}
		}
		if { $::MAIN_LOG && $::MAIN_LOG_SHOW } {
			set tag ""
			set end ""
			if { [regexp {^(.*)(< */[Bb][Oo][Dd][Yy] *>)(.*)$} $content match result tag end] } {
				set content $result
			}
			regsub -all {[^01-9\-]} $::MAIN_LOG_FILENAME {} deb_id
			append content "&nbsp;<font size=\"-1\"><a href=\"$::FAS_VIEW_URL?file=[rm_root ${filename}]&action=show_debug_file&debug_identifier=${deb_id}&mainlog=1\">Main log file</a></font>${tag}${end}"
		}
		return $content
	}

	# A single procedure to create right url
	#  relative ones are changed in absolute + fas_view.cgi before
	#  fas:/ are changed into fas_view.cgi?file=....
	proc to_right_url { str re filename } {
		fas_fastdebug {fashtml::to_right_url - Entering}
		global FAS_VIEW_URL
		variable local_conf
		set result ""

		global conf
		if {[regexp $re $str match start url end]} {
			fas_fastdebug {fashtml::to_right_url - matched {$re} with {$str}}
			
			if { [info exists conf(tclhttpd)] || [info exists conf(tclrivet)] } {
			#if { ![info exists conf(websh)] || ![info exists conf(cgi) } {
				regsub -all "\&" $url "\&amp;" url
				regsub -all {\&amp;#64;} $url {\&#64;} url
			}
			#}

			if { ![regexp ":" $url match] && ![regexp {[?]} $url match] && [string range $url 0 0] != "/" } {
				# it is a relative link I must transform it into an absolute link
				fas_fastdebug {fashtml::to_right_url - url is relative... changing to absolute}

				set result "${FAS_VIEW_URL}$local_conf(fas_view_url)[file join [rm_root [file dir $filename]] $url]"

			# begin modif Xav "fas:(.*)"
			# correcting an important bug here with fas: followed by nothing
			# the greedy expression fas:(.*) is able to take the whole tail
			# of the html document !
			# so that the documents never ends, which results in an apache thread
			# keeping working for ever and for nothing...
			# solution : we match only everything before " or < or >
			} elseif {[regexp {fas:(.*)([\"<>]+.*)?} $url match relative_url stringafter]} {
				# then it is a fas: url type
				# I transform it into fas_view.cgi ...

				fas_fastdebug {fashtml::to_right_url - fas: case}
				set result "${FAS_VIEW_URL}$local_conf(fas_view_url)$relative_url$stringafter"

			} elseif {[regexp {!fas:(.*)([\"<>]+.*)?} $url match relative_url stringafter]} {
				#do nothing in the !fas case
				
				fas_fastdebug {fashtml::to_right_url - !fas: case}
				set result "$filename$stringafter"
			# end modif Xav
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
	# A single procedure to create right url
	#  relative ones are changed in absolute + fas_view.cgi before
	#  fas:/dsdf   are changed in fas_view.cgi?file=....
	proc to_right_url_mod_rewrite { str re filename } {
		fas_fastdebug {fashtml::to_right_url_mode_rewrite - Entering}
		global FAS_VIEW_REWRITE_URL
		set result ""

		if {[regexp $re $str match start url end]} {
			regsub -all "\&" $url "\&amp;" url
			regsub -all {\&amp;#64;} $url {\&#64;} url

			if { ![regexp ":" $url match] && ![regexp {[?]} $url match] && [string range $url 0 0] != "/" } {
				# it is a relative link I must transform it into an absolute link
			
				set result "${FAS_VIEW_REWRITE_URL}[file join [rm_root [file dir $filename]] $url]"
			} elseif {[regexp "fas:(.*)" $url match relative_url]} {
				# then it is a fas: url type
				# I transform it into fas_view.cgi ...
				set result "${FAS_VIEW_REWRITE_URL}$relative_url"
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

	proc get_title { filename } {
		set title ""
		if { ![catch {open $filename} fid] } {
			set file [read $fid]
			close $fid
			regexp {< *[Tt][Ii][Tt][Ll][Ee] *>(.*?)< */[Tt][Ii][Tt][Ll][Ee] *>} $file match title
		}
		return $title
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

	proc content_display { current_env content } {
		fas_debug "fas_html::content_display - entering"
		return "[not_binary::content_display fashtml $content]"
	}

	proc display { current_env filename } {
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename fashtml]"
	}

	proc content { current_env filename } {
		upvar $current_env fas_env
		return "[not_binary::content fas_env $filename fashtml]"
	}

	proc 2txt4index { current_env filename } {
		upvar $current_env fas_env
		set real_filename [fas_name_and_dir::get_real_filename fashtml $filename fas_env]
		#variable local_conf

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		# fas_depend::set_dependency $filename fas_env

		# fas_debug "fashtml::2txt4index - processing html file with lynx"
		# set fid [eval open \"|$local_conf(html.lynx) $real_filename\"]
 		# if { [catch { set content [read $fid]} error] } {
 		#	fas_display_error "fashtml::2txt4index - [translate "problem while processing"] $real_filename<br>$error" -file $filename
 		#	return ""
 		# }
 		# close $fid
		# I do it only in tcl and that's it
		set content ""
		if { [catch { set fid [open $real_filename]
			set content [read $fid]
			close $fid
		} ] } {
			fas_display_error "fashtml::2txt4index - [translate "problem while reading "] $real_filename<br>$error" -file $filename
			set content "fashtml::2txt4index - [translate "problem while reading "] $real_filename<br>$error"
		} else {
			regsub -all {<[^>]+>} $content {} content
			regsub -all {&nbsp;} $content { } content
			regsub -all {&lt;} $content {<} content
			regsub -all {&amp;} $content {\&} content
			regsub -all {&gt;} $content {>} content
		}
		return $content
	}	
}
