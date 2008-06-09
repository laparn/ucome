namespace eval binary {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	set local_conf(convert.small) "/usr/bin/convert -resize 120x120 "
	set local_conf(convert.middle) "/usr/bin/convert -resize 800x800 "

	proc new_type { current_env filename filetype } {
		upvar $current_env fas_env

		fas_fastdebug {binary::new_type $filename $filetype}
		# When a binary is met, in what filetype will it be by default
		# translated ?

		# If there is an action, I use it
		if { ![catch {set action [fas_get_value action] } ] } {
			# there is an action. Is it done or not
			if { $action != "view" } {
				if { [set ${action}::done ] == 0 } {
					fas_debug "binary::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}

		# begin modif Xav
		# manage the "target=rrooll" option for all binary files
		if { ![catch {set target [fas_get_value target -noe]}] } {
			if { $target == "rrooll" || $target == "rool" } {

				fas_debug_parray fas_env "binary::new_type fas_env before down_stage_env with rool"

				down_stage_env fas_env "rrooll.cgi_uservar."

				fas_debug_parray fas_env "binary::new_type fas_env after down_stage_env with rool"
				return comp
			} elseif { $target == "html" } {
				return comp
			} elseif { $target == "xspf" } {
				return xspf
			}
		}
		# end modif Xav

		# It's nothing just a binary
		return ""
		#error 1
	}
	
	proc 2edit { current_env filename filetype} {
		upvar $current_env fas_env

		global _cgi_uservar

		unset _cgi_uservar
		set _cgi_uservar(message) "$filetype [translate "file can not be edited"]"
		set dir_name [file dirname $filename]
		#set _cgi_uservar(edit_dir) 1
		set _cgi_uservar(action) edit_form
		global conf
		display_file dir $dir_name fas_env conf
		fas_exit
	}

	proc get_title { filename } {
		# basically, I do not know the title of the file
		return "&nbsp;"
		#return "none / unknown"
	}
	
	proc content { current_env filename filetype } {
		# A procedure for just giving back the file  directly
		# Here there are 2 cases, either it is the real file
		# or I must take the file from the html cache directory.
		upvar $current_env fas_env

		fas_debug "binary::content env $filename $filetype"
		# it is a file
		# So I first look in the cache directory
		set content "binary::content - Nothing to display $filetype"
		if { [catch {set content [get_cache_file_content $filetype $filename fas_env]} ] } {
				global errorInfo
				fas_display_error "${filetype}::binary::display - Problem while getting $filename\n$errorInfo" fas_env -file $filename
		} else {
				return $content
		}
	}

	proc 2small { current_env filename filetype } {
		# I need to convert to a small png, gif, jpeg
		# then to send it back
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename $filetype $filename fas_env]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		# start the conversion
		variable local_conf
		fas_debug "binary::2small :|$local_conf(convert.small) \"$real_filename\" -"
		global _cgi_uservar
		if { [info exists _cgi_uservar(middle) ] } {
			set fid [eval open \"|$local_conf(convert.middle) \\\"$real_filename\\\"  ${filetype}:-\"]
		} else {
			set fid [eval open \"|$local_conf(convert.small) \\\"$real_filename\\\"  ${filetype}:-\"]
		}
		fconfigure $fid -translation { binary binary }
                #fconfigure stdout -translation { binary binary }

		set content ""
		if { [catch { set content [read $fid]} error] } {
			# I should have a binary png displaying error binary encoded
			set content "binary::2small - [translate "problem while processing"] $real_filename<br>$error"
		}
		catch { close $fid }
		return $content
	}


	
	# modif Xav
	# it is the same in the most of binary namespaces so I put it here.
	proc content_display { current_env content } {
		_cgi_http_head_implicit
		puts "$content"
	}

	proc display { filetype mimetype filename current_env } {
		# A procedure for just sending the output on the
		# stdout.
		fas_debug_puts "${filetype} :: display"

		upvar $current_env env
		if { [catch {set real_filename [fas_name_and_dir::get_real_filename $filetype $filename env ] } ] } {
			# problem while searching for the real file
			fas_display_error "${filetype} :: display - [translate "Problem while searching for"] $filename" env -file $filename
		} else {
			global conf
			if { ![info exists conf(tclhttpd)] && ![info exists conf(tclrivet)] && ![info exists conf(websh)] } {
				# cgi case
				# outputting http headers & file
				fas_debug "binary::display - cgi - $filename - type $mimetype"
				cgi_output $real_filename $mimetype
			} elseif { [info exists conf(tclrivet)] } {
				# tcl rivet case
				fas_debug "binary::display - rivet - $filename - type $mimetype"
				rivet_output $real_filename $mimetype
			} elseif { [info exists conf(websh)] } {
				fas_debug "binary::display - websh - $filename - type $mimetype"
				websh_output $real_filename $mimetype
			} else {
				# tclhttpd case
				set sock $conf(sock) 
				Httpd_ReturnFile $sock $mimetype $real_filename
			}
			fas_depend::write_complete_dependency $filename env
			fas_depend::write_final_filetype $filetype
			fas_depend::write_final_filename env $real_filename
		}
	}

	proc display_cache { filetype real_filename current_env } {
		# A procedure for just sending the output on the
		# stdout.
		fas_debug_puts "${filetype} :: display_cache"

		upvar $current_env fas_env
		if { [catch {set mimetype [${filetype}::mimetype]} ] } {
			# This is a very special case : I try to avoid
			# sourcing all code in the cgi case (it is very long)
			# I try to source "on demand" (Copyright HAL)
			if { [catch { 
				#uplevel #0 source ${::FAS_PROG_ROOT}/mimeprocs/${filetype}.tcl
				namespace eval :: source ${::FAS_PROG_ROOT}/mimeprocs/${filetype}.tcl
				set mimetype [${filetype}::mimetype]
			} ] } {
				set mimetype "text/html"
			}
		}
		global conf
		if { ![info exists conf(tclhttpd)] && ![info exists conf(tclrivet)] && ![info exists conf(websh)] } {
			# cgi case

			# outputting http headers & file
			fas_debug "binary::display_cache $real_filename - type $mimetype"
			cgi_output $real_filename $mimetype

		} elseif { [info exists conf(tclrivet)] } {
			# tcl rivet case

			fas_debug "binary::display_cache rivet $real_filename - type $mimetype"
			rivet_output $real_filename $mimetype

		}  elseif { [info exists conf(websh)] } {
			fas_debug "binary::display_cache - websh - $real_filename - type $mimetype"
			websh_output $real_filename $mimetype
		} else {
			# tclhttpd case
			set sock $conf(sock) 
			Httpd_ReturnFile $sock $mimetype $real_filename
		}
	}

	proc mimetype { } {
		return "application/binary"
	}

	proc cgi_output { filename filetype } {
		# Now sending the output
		set fileid [open $filename]
		set fsize [file size $filename]
		set fdate [file mtime $filename]
		set fdate [clock format $fdate -format "%a, %d %b %Y %H:%M:%S %Z" -gmt true]
		puts stdout "Content-type: $filetype"
		puts stdout "Last-modified: $fdate"
		puts stdout "Content-length: $fsize"
		#puts stdout "Cache-control: private, no-store, no-transform, must-revalidate"
		puts stdout "Accept-ranges: bytes"
		#puts stdout "Content-disposition: attachment; filename=[file tail $filename]"
		# With apache2, I have a redirect (302), so I 
		# suppress the 2 following lines
		# june 2008
		#puts stdout "Location: [file tail $filename]"
		#puts stdout "Content-location: [file tail $filename]"
		puts stdout ""

		# Outputing the file :
		fconfigure $fileid -translation { lf lf }
		fconfigure stdout -translation { lf lf }
		flush stdout
		fcopy $fileid stdout
		catch { close $fileid }
	}

	proc rivet_output { filename filetype } {
		if { [catch {headers type $filetype} ] } {
		    error "OOOOps - header written twice - error to be found !!!!"
		} else {

			set fsize [file size $filename]
			set fdate [file mtime $filename]
			set fdate [clock format $fdate -format "%a, %d %b %Y %H:%M:%S %Z" -gmt true]

			# the filetype should always be send, even if sent twice
			headers type $filetype

			headers set Last-modified $fdate
			headers set Content-length $fsize
			#headers set Cache-control "private, no-store, no-transform, must-revalidate"
                        # The next line causes problem with mplayer 
                        # It leads to the following error message :
                        # Resolving localhost for AF_INET...
                        # Connecting to server localhost[127.0.0.1]:80 ...
                        # with the manual command :
                        # mplayer http://localhost/ucome.rvt?file=/any/rool/temple_mp4.avi
                        # ==============================
			#headers set Accept-ranges "bytes"
                        # ==============================

			# do not activate the line hereunder ! seems to cause strange errors...
			## indeed it forces the browser to download the file !
			# headers set Content-Disposition "attachment;filename=\"[file tail $filename]\""

			# when using tcl sockets (useless with rivet include directive)
			# it seems that these two lines greatly improve speed
			# Why ???
			headers set Location [file tail $filename]
			headers set Content-Location [file tail $filename]

			# Outputing the file :
			# the line below should be the only one to put
			# but this doesn't seem to work for videos.
			## yes yes, it works ! (the trouble was squid, at least...)
			include $filename
			# translation should be to lf also, but it doesn't work well here.
			#set fileid [open $filename]
			#fconfigure $fileid -translation { binary binary }
			#fconfigure stdout -translation { binary binary }
			#flush stdout
			#fcopy $fileid stdout
			#catch { close $fileid }
		}
	}
	proc websh_output { filename filetype } {
		# Now sending the output
		set fileid [open $filename]
		fconfigure $fileid -translation { lf lf }
		set tmp [read $fileid]
		catch { close $fileid }
		set fsize [file size $filename]
		set fdate [file mtime $filename]
		set fdate [clock format $fdate -format "%a, %d %b %Y %H:%M:%S %Z" -gmt true]
		web::response -set Content-Type ${filetype}
		web::response -set Last-modified "$fdate"
		web::response -set Content-length "$fsize"
		#puts stdout "Cache-control: private, no-store, no-transform, must-revalidate"
		web::response -set Accept-ranges "bytes"
		#puts stdout "Content-disposition: attachment; filename=[file tail $filename]"
		web::response -set Location "[file tail $filename]"
		web::response -set Content-location "[file tail $filename]"

		# Outputing the file :
		#fconfigure $fileid -translation { lf lf }
		#fconfigure [web::response] -translation { lf lf }
		#fcopy $fileid [web::response]
		#web::putxfile [web::response] $filename
		web::put [web::response] $tmp  
	}

}
