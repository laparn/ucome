# Extension will be 0001 0002 ....
#set conf(extension.png) png
lappend filetype_list tiffg3

namespace eval tiffg3 {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	set local_conf(tiffg3.convert) "/usr/bin/convert"
	set local_conf(tiffg3.small) "$local_conf(tiffg3.convert) -resize 200x300 "

	proc new_type { current_env filename } {
		fas_fastdebug {tiffg3::new_type $filename}
		upvar $current_env fas_env
		set result png
		# When a tiff is met, in what filetype will it be by default
		# translated ?
		# begin modif Xav : this is done in binary
		#if { ![catch {set action [fas_get_value action] } ] } {
		#	if { $action != "view" } {
		#		# there is an action. Is it done or not
		#		if { [set ${action}::done ] == 0 } {
		#			fas_debug "tiffg3::new_type - action -> $action , action::done -> [set ${action}::done]"
		#			# the action was not processed
		#			set result $action
		#			return $result
		#		} ; # else I continue
		#	}
		#}
		# end modif Xav
		if { ![catch {set target [fas_get_value target -noe]}] } {
			# we are in the standard case nothing to do
			switch -exact -- $target {
				ori {
					#error 1
					return ""
				}
			}
		}

		# modif Xav return $result
		return [binary::new_type fas_env $filename tiffg3]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	
	proc env { args } {
		set env_list ""
		return $env_list
	}

	proc get_title { filename } {
		# I am going to try to display a small vignette
		set title "<img src=\"fas:[rm_root $filename]&action=small\">"
		return "$title"
	}

	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename png
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename png
	}

	proc 2rrooll { current_env filename } {
		fas_fastdebug {tiffg3::2rrooll $filename}
		upvar $current_env fas_env
		return "[rrooll::2fashtml fas_env $filename tiffg3]"
	}

	proc 2png { current_env filename } {
		# I need to convert into a png
		# then to send it back
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename tiffg3 $filename fas_env]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		# start the conversion
		variable local_conf
		fas_debug "tiffg3::2png :|$local_conf(tiffg3.convert) $real_filename  png:-"
		set fid [eval open \"|$local_conf(tiffg3.convert) $real_filename  png:-\"]
		set content ""
		fconfigure $fid -translation { binary binary }
                fconfigure stdout -translation { binary binary }
		if { [catch { set content [read $fid]} error] } {
			# I should have a binary png displaying error binary encoded
			set content "tiffg3::2fashtml - [translate "problem while processing"] $real_filename<br>$error"
		}
		catch { close $fid }
		return $content
	}
		
	proc 2small { current_env filename } {
		# I need to convert to a small png
		# then to send it back
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename tiffg3 $filename fas_env]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		# start the conversion
		variable local_conf
		fas_debug "tiffg3::2png :|$local_conf(tiffg3.convert) $real_filename -type png -"
		set fid [eval open \"|$local_conf(tiffg3.small) \\\"$real_filename\\\"  png:-\"]
		fconfigure $fid -translation { binary binary }
                #fconfigure stdout -translation { binary binary }

		set content ""
		if { [catch { set content [read $fid]} error] } {
			# I should have a binary png displaying error binary encoded
			set content "tiffg3::2fashtml - [translate "problem while processing"] $real_filename<br>$error"
		}
		catch { close $fid }
		return $content
	}
		

	proc content_display { current_env content } {
		## modif Xav : that proc is gone into binary
		binary::content_display $current_env $content
	}
	
	proc display { current_env filename } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env env
	
		# it is a file
		binary::display tiffg3 image/tiff $filename env
	}

	proc content { current_env filename } {
        upvar $current_env fas_env
		return [binary::content $current_env $filename tiffg3]
	}

	proc mimetype { } {
		return "image/tiff"
	}
}
