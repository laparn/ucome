set conf(extension.jpg) jpeg
set conf(extension.jpeg) jpeg
lappend filetype_list jpeg

namespace eval jpeg {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	set local_conf(convert.small) "/usr/bin/convert -resize 120x120 "

	proc new_type { current_env filename } {
		fas_fastdebug {jpeg::new_type $filename}
		upvar $current_env fas_env
		# When a jpeg is met, in what filetype will it be by default
		# translated ?
		return [binary::new_type fas_env $filename jpeg]
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
		#return "[binary::get_title $filename]"
		set title "<a href=\"fas:[clean_filename [rm_root $filename]]&target=html\"><img src=\"fas:[clean_filename [rm_root $filename]]&action=small\"></a>"
		return "$title"
	}

	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename jpeg
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename jpeg
	}
	
	# Used when a jpeg must be displayed in a rool case.
	# So display at screen center and then create an apparition effect
	proc tocomp_rool_case { current_env filename } {
		upvar $current_env fas_env
		# First I need the size of the picture.
		# Then I will give this parameter to a javascript function
		# So I need to find a template, and substitute values in it
		set width -1
		set height -1
		set identify_string [exec identify $filename]
		regexp {([0-9]+)x([0-9]+)} $identify_string match width height
		# Do I have a property for an arrival of the image ?
		set arrival down
		if { [info exists fas_env(jpeg.arrival)] } {
			set arrival $fas_env(jpeg.arrival)
			if { [lsearch [list left right up down opacity] $arrival] == -1 } {
				set arrival down
			}
		}
		# Ok getting the template
		set real_filename [fas_name_and_dir::get_real_filename jpeg $filename fas_env]
		fas_depend::set_dependency $real_filename file
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env jpeg.template] } errStr] } {
			fas_display_error "jpeg::tocomp_rool_case - [translate "Problem getting template name"] jpeg.template<br>${errStr}" fas_env
		}
		fas_depend::set_dependency $template_name file
		# Ok substituting and leaving
		if { [catch { atemt::read_file_template_or_cache "JPEG_TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "jpeg::tocomp_rool_case - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}

		# Preparing the variables
		fas_debug "jpeg::tocomp_rool_case - filename is $filename"
		global FAS_VIEW_CGI
		set export_filename [rm_root $filename]

		# We substitute the variables
		atemt::atemt_set JPEG_TEMPLATE -bl [atemt::atemt_subst -block CONTENT JPEG_TEMPLATE]
		# Here there is filename and dir to substitute
		set tmp(content.content) [extract_body [atemt::atemt_subst -end JPEG_TEMPLATE]]
		return "[array get tmp]"
	}
		
	proc 2comp { current_env filename } {
		upvar $current_env fas_env

		global _cgi_uservar
		if { [info exists _cgi_uservar(target)] } {
			if { $_cgi_uservar(target) == "rool" || $_cgi_uservar(target) == "rrooll" } {
				# I am in the rool case
				return [tocomp_rool_case fas_env $filename]
			}
		}
		# I am in the normal gallery case
		# Here I should :
		# Find what are the next and previous images,
		# Show them in small as next and previous
		# Show the jpeg in small target=middle
		# And if there is a photo comment under the image,
		# I should show it.

		# First next / previous image
		set dir [file dirname $filename]
		set tail [file tail $filename]
		set list_image [glob -nocomplain -directory $dir "*.jpg" "*.jpeg"]
		# Where is the current image ?
		set list_index_image [lsearch -exact $list_image $filename]
		set dir_length [llength $list_image]
		
		if { $list_index_image < 0 } {
			set content "<br><a href=\"fas:[clean_filename [rm_root $filename]]\"><img src=\"fas:[clean_filename [rm_root $filename]]&action=small&middle=1\"></a>"
		} elseif { $list_index_image == 0 } {
			if { $dir_length > 1 } {
				set next_image [lindex $list_image 1]
				set content "<br><a href=\"fas:[clean_filename [rm_root $filename]]\"><img src=\"fas:[clean_filename [rm_root $filename]]&action=small&middle=1\"></a><br><a href=\"fas:[clean_filename [rm_root $next_image]]&target=html\"><img src=\"fas:[clean_filename [rm_root $next_image]]&action=small\" alt=\"Suivant\"></a>"
			} else {
				set content "<br><a href=\"fas:[clean_filename [rm_root $filename]]\"><img src=\"fas:[clean_filename [rm_root $filename]]&action=small&middle=1\"></a>"
			}
		} elseif { $list_index_image == [incr dir_length -1] } {
			if { $dir_length > 1 } {
				set previous_image [lindex $list_image end-1]
				set content "<br><a href=\"fas:[clean_filename [rm_root $filename]]\"><img src=\"fas:[clean_filename [rm_root $filename]]&action=small&middle=1\"></a><br><a href=\"fas:[clean_filename [rm_root $previous_image]]&target=html\"><img src=\"fas:[clean_filename [rm_root $previous_image]]&action=small\" alt=\"Précédent\"></a>"
			} else {
				set content "<br><a href=\"fas:[clean_filename [rm_root $filename]]\"><img src=\"fas:[clean_filename [rm_root $filename]]&action=small&middle=1\"></a>"
			}
		} else {
			set next_image [lindex $list_image [expr $list_index_image + 1]]
			set previous_image [lindex $list_image [expr $list_index_image - 1]]
			set content "<br><a href=\"fas:[clean_filename [rm_root $filename]]\"><img src=\"fas:[clean_filename [rm_root $filename]]&action=small&middle=1\"></a><br><a href=\"fas:[clean_filename [rm_root $previous_image]]&target=html\"><img src=\"fas:[clean_filename [rm_root $previous_image]]&action=small\" alt=\"Précédent\"></a>&nbsp;<a href=\"fas:[clean_filename [rm_root $next_image]]&target=html\"><img src=\"fas:[clean_filename [rm_root $next_image]]&action=small\" alt=\"Suivant\"></a>"
		}
		set tmp(content.content) "$content"
		return "[array get tmp]"
	}

	proc 2rrooll { current_env filename } {
		fas_fastdebug {jpeg::2rrooll $filename}
		## specific processings prior to rrooll
		## may be done here.

		upvar $current_env fas_env
		return "[rrooll::2fashtml fas_env $filename jpeg]"
	}

	proc 2xspf { current_env filename } {
		fas_fastdebug {jpeg::2xspf $filename entering}
		upvar $current_env fas_env
		set export_filename [rm_root $filename]
		set content "<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\">
        <trackList>
                <track>
                        <title>[rm_root $filename]</title>
                        <creator>AL</creator>
			<location>[fashtml::to_right_url "fas:$export_filename" "" ""]$export_filename</location> 
                        <info></info>
                </track>
        </trackList>
</playlist>"
		return $content
	}

	proc 2small { current_env filename } {
		# I need to convert to a small png
		# then to send it back
		upvar $current_env fas_env
		set content [binary::2small fas_env $filename jpeg]
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
		binary::display jpeg image/jpeg $filename env
	}

	proc content { current_env filename } {
        upvar $current_env fas_env
    	return [binary::content $current_env $filename jpeg]
	}


	proc mimetype { } {
		return "image/jpeg"
	}
}
