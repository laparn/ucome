# Standard functions for not binary files (txt, tmpl, html, htmf, javascript, css)
namespace eval not_binary {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	proc get_title { filename } {
		fas_debug "not_binary::get_title entering"
		# The title is the first line of the file
		set title ""
		if { ![catch {open $filename} fid] } {
			set title [gets $fid]
			close $fid
		}
		fas_debug "not_binary::get_title found ->$title<-"
		return $title
	}
	
	proc insert_before_body { content content_to_insert } {
		set debug_index [string last "</body>" $content]
		if { $debug_index == -1 } {
			set debug_index [string last "</BODY>" $content]
		}
		if { $debug_index == -1 } {
			set debug_index [string length $content]
		}
		if $debug_index {
			incr debug_index -1
		}
		set content [string replace $content $debug_index $debug_index $content_to_insert]
		return $content
	}

	# content_display but without any session management
	# used for css and javascript
	# This procedure is used for css, javascript
	proc content_display { filetype content } {
		global conf
		fas_debug "not_binary::content_display $filetype content"
		if { ![info exists conf(tclhttpd)] && ![info exists conf(tclrivet)] && ![info exists conf(websh)] } {
			cgi_http_head {
				cgi_content_type [${filetype}::mimetype]
			}
			#_cgi_http_head_implicit
			# I added the cgi_body for the debug getting cookies and variables
			puts "$content"
		} elseif { [info exists conf(tclrivet)] } {
			if { [catch {headers type [${filetype}::mimetype]} ] } {
				puts "$content"
			} else {
				puts "$content"
			}
		} elseif { [info exists conf(websh)] } {
			if { [catch {${filetype}::mimetype} mimet] } {
				set mimet text/html
			}
			web::response -set Content-Type $mimet
			web::put "$content"
		} else {
			set sock $conf(sock) 
			Httpd_ReturnData $sock [${filetype}::mimetype] "$content"
		}
	}


	# This procedure is used for css, javascript, rool (!)
	proc content_display_with_session { filetype content } {
		global conf
		#fas_debug "not_binary::content_display $filetype content"
		# Now all is done in fashtml with links
		#global MAIN_LOG MAIN_LOG_SHOW
		#if { $MAIN_LOG && $MAIN_LOG_SHOW } {
		#	global MAIN_LOG_STRING
		#	set main_log "<BR><H2>MAIN_LOG</H2><PRE>${MAIN_LOG_STRING}</PRE>"
		#	set content [insert_before_body $content $main_log]
		#}
		#global DEBUG DEBUG_SHOW _cgi_uservar
		#if { $DEBUG && $DEBUG_SHOW } {
		#	set debug_content "<BR><H2>DEBUG</H2><H3>CGI VARIABLES</H3>"
		#	global DEBUG_STRING
		#	foreach element [array names _cgi_uservar] {
		#		append debug_content "<b>$element</b> -> $_cgi_uservar($element)<BR>\n"
		#	}
		#	append debug_content "<H3>DEBUG TRACE</H3>"
		#	append debug_content "<PRE>\n${DEBUG_STRING}\n</PRE>"
		#	set content [insert_before_body $content $debug_content]
		#}
		if { ![info exists conf(tclhttpd)] && ![info exists conf(tclrivet)] && ![info exists conf(websh)] } {
			cgi_http_head {
				cgi_content_type [${filetype}::mimetype]
				fas_session::export_session
			}
			#_cgi_http_head_implicit
			# I added the cgi_body for the debug getting cookies and variables
			puts "$content"
		} elseif { [info exists conf(tclrivet)] } {
			if { [catch {headers type [${filetype}::mimetype]} ] } {
				puts "$content"
			} else {
				fas_session::export_session
				puts "$content"
			}
		} elseif { [info exists conf(websh)] } {
			if { [catch {${filetype}::mimetype} mimet] } {
				set mimet text/html
			}
			fas_session::export_session
			# There is an error here. fas_context::commit should work
			# but if I put it, nothing is outputed. I do not understand.
			# ERROR - to be seen with websh people.
			fas_context::commit
			web::response -set Content-Type $mimet
			web::put "$content"
		} else {
			set sock $conf(sock)
			# ????????????? to be checked 
			fas_session::export_session
			package require httpd::cookie
			Cookie_Save $sock
			Httpd_ReturnData $sock [${filetype}::mimetype] "$content"
		}
		fas_session::write_session
	}
	
	proc display { current_env filename filetype } {
		# A procedure for just displaying the file  directly
		# Here there are 2 cases, either it is the real file
		# or I must take the file from the html cache directory.
		upvar $current_env fas_env
		fas_debug "not_binary::display env $filename $filetype"

		# it is a file
		# So I first look in the cache directory
		set content "non_binary::display - Nothing to display $filetype"
		global conf
		# For tclhttpd : BUG
		# It is much quicker to use Httpd_ReturnFile however, each time I use
		# it when there is an internal page redirection (and the call of fas_exit)
		# I get a half page display. It is known that there are some bugs there
		# and I tried a patch, but it does not change. Maybe with a more recent
		# version ? To be seen.
		#if { [info exists conf(tclhttpd) ] } {
		#	set sock $conf(sock)
		#	fas_debug "not_binary::display tclhttpd case - Httpd_ReturnFile $sock [${filetype}::mimetype] [fas_name_and_dir::get_real_filename $filetype $filename fas_env]"
		#	Httpd_ReturnFile $sock [${filetype}::mimetype] [fas_name_and_dir::get_real_filename $filetype $filename fas_env]
		#} else {
		#	if { [catch {set content [get_cache_file_content $filetype $filename fas_env]} ] } {
		#		global errorInfo
		#		fas_display_error "${filetype}::nonbinary::display - Problem while getting $filename\n$errorInfo" fas_env -file $filename
		#	} else {
		#		${filetype}::content_display fas_env $content
		#	}
		#}
		# Just a small test to see what happen in using not_binary::display
		#if { [catch {set content [get_cache_file_content $filetype $filename fas_env]} ] } {
		#	global errorInfo
		#	fas_display_error "${filetype}::nonbinary::display - Problem while getting $filename\n$errorInfo" fas_env -file $filename
		#} else {
			#${filetype}::content_display fas_env $content
		#	content_display fas_env $filetype $content
		#	fas_depend::write_complete_dependency $filename fas_env
		#	fas_depend::write_final_filetype fas_env $filetype $filename
		#}

		#set mimetype [${filetype}::mimetype]
		#binary::display $filetype $mimetype $filename fas_env

		# Finally a test with a mixed not_binary::content_display
		# and binary::display
		if { [catch {set real_filename [fas_name_and_dir::get_real_filename $filetype $filename fas_env ] } ] } {
			fas_display_error "${filetype} :: display - [translate "Problem while searching for"] $filename" env -file $filename
		} else {
			set mimetype [${filetype}::mimetype]
			global conf
			if { ![info exists conf(tclhttpd)] && ![info exists conf(tclrivet)] && ![info exists conf(websh)] } {
				cgi_http_head {
					cgi_content_type $mimetype
					fas_session::export_session
				}
				#_cgi_http_head_implicit
				# I added the cgi_body for the debug getting cookies and variables
				set fileid [open $real_filename]
				fconfigure $fileid -translation { binary binary }
				fconfigure stdout -translation { binary binary }
				flush stdout
				fcopy $fileid stdout
				catch { close $fileid }
			} elseif { [info exists conf(tclrivet)] } {
				fas_session::export_session
				::binary::rivet_output $real_filename $mimetype
				#if { [catch {headers type $mimetype} ] } {
                                #        puts "not_binary::display Ooops - headers sent twice ??? Error to be found"
                                #} else {
				    #headers set Content-Disposition "attachment;filename=\"[file tail $filename]\""
				#    fas_session::export_session
				    #set fileid [open $real_filename]
				    # Outputing the file :
				#    fconfigure $fileid -translation { binary binary }
				#    fconfigure stdout -translation { binary binary }
				#    flush stdout
				#    fcopy $fileid stdout
				#    catch { close $fileid }
                                #}
			}  elseif { [info exists conf(websh)] } {
				fas_session::export_session
				fas_context::commit 
				::binary::websh_output $real_filename $mimetype	
			} else {
				fas_debug "not_binary::content_display tclhttpd case"
				# I am in the tclhttpd case, I do something
				set sock $conf(sock)
				# ????????????? to be checked 
				fas_session::export_session
				package require httpd::cookie
				Cookie_Save $sock
				Httpd_ReturnFile $sock $mimetype $real_filename
			}
			fas_depend::write_complete_dependency $filename env
			fas_depend::write_final_filetype $filetype
			fas_depend::write_final_filename env $real_filename
		}
		fas_session::write_session
	}
	
	proc content { current_env filename filetype } {
		# A procedure for just giving back the file  directly
		# Here there are 2 cases, either it is the real file
		# or I must take the file from the html cache directory.
		upvar $current_env fas_env

		fas_debug "not_binary::content env $filename $filetype"
		# it is a file
		# So I first look in the cache directory
		set content "non_binary::content - Nothing to display $filetype"
		if { [catch {set content [get_cache_file_content $filetype $filename fas_env]} ] } {
			global errorInfo
			fas_display_error "${filetype}::nonbinary::display - Problem while getting $filename\n$errorInfo" fas_env -file $filename
		} else {
			global DEBUG
			global IN_COMP
			return $content
			# I see no reason to bother for debug when giving back content
			#if { !$DEBUG || $IN_COMP } {
			#	fas_debug "not_binary::content -> returning $content"
			#	return "$content"
			#} else {
			#	global DEBUG_STRING
			#	set start ""
			#	set tag ""
			#	set end ""
			#	if { [regexp {^(.*)(< */[Bb][Oo][Dd][Yy] *>)(.*)$} $content match start tag end] } {
			#		global _cgi_uservar
			#		set error_content "$start<BR><HR>$IN_COMP<BR>"
			#		foreach element [array names _cgi_uservar] {
			#			append error_content "$element -> $_cgi_uservar($element)<BR>"
			#		}
			#		append error_content "<HR>"
			#		fas_debug "not_binary::content body + error ->$start <---------------"

			#		return "${error_content}\n<!-- DEBUG -->\n<BR>\n<HR>\n<PRE>\n${DEBUG_STRING}\n</PRE>\n<!-- /DEBUG -->\n${tag}\n${end}"
			#	} else {
			#		# No body tag, I just append the debug
			#		set error_content "${content}\n<!-- DEBUG -->"
			#		global _cgi_uservar
			#		set error_content "$start<BR><HR>$IN_COMP<BR>"
			#		foreach element [array names _cgi_uservar] {
			#			append error_content "$element -+ $_cgi_uservar($element)<BR>"
			#		}
			#		append error_content "<HR>"
			#		fas_debug "not_binary::content + error -\n${content}\n+-----------------"
			#		return "${error_content}\n\n<PRE>\n${DEBUG_STRING}\n</PRE>\n<!-- /DEBUG -->"
			#	}
			#}
		}
	}
}


