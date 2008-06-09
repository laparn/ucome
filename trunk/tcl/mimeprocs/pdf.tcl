set conf(extension.pdf) pdf

lappend filetype_list pdf

namespace eval pdf {

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		upvar $current_env fas_env
		# When a pdf is met, in what filetype will it be by default
		# translated ?
		return [binary::new_type fas_env $filename pdf]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	proc get_title { filename } {
		return "[binary::get_title $filename]"
	}

	# Return the list of environment variables that are important
	# If this function is not defined, it is a final type that can
	# not be converted
	proc env { args } {
		set env_list ""
		return $env_list
	}

	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename pdf
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename pdf
	}
		

	proc content_display { current_env content } {
		puts "Content-type: application/pdf\n"
		puts "$content"
	}

	proc display { current_env filename  } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env env
	
		# it is a file
		if { [catch {set real_filename [fas_name_and_dir::get_real_filename pdf $filename env ] } ] } {
			# problem while searching for the real file
			fas_display_error "pdf::display - [translate "Problem while searching for"] $filename" env -file $filename
		} else {
			# Now sending the output
			global conf
			if { ![info exists conf(tclhttpd)] && ![info exists conf(tclrivet)] } {
				set fileid [open $real_filename]
				puts stdout "Content-type: application/pdf\n"
				puts stdout "Content-Disposition: attachment;filename=\"[file tail $filename]\"\n"

				fconfigure $fileid -encoding binary -translation binary
				fconfigure stdout -encoding binary -translation binary
				flush stdout
				fcopy $fileid stdout
				# Outputing the file :
				catch { close $fileid }
			} elseif { [info exists conf(tclrivet)] } {
				# tcl rivet case
				headers type "application/pdf"
				headers set Content-Disposition "attachment;filename=\"[file tail $filename]\""
				set fileid [open $real_filename]
				# Outputing the file :
				fconfigure $fileid -translation { binary binary }
				fconfigure stdout -translation { binary binary }
				flush stdout
				fcopy $fileid stdout
				catch { close $fileid }
			} else {
				set sock $conf(sock) 
				Httpd_ReturnFile $sock "application/pdf" $real_filename
			}
		}
	}
	# Procedure for storing a binary file
	proc write_cache_file { fid content } {
		fas_debug "pdf::write_cache_file - entering"
		fconfigure $fid -encoding binary -translation binary
		puts $fid $content
		close $fid
	}
}
