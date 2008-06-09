set conf(extension.mpeg) mpeg
lappend filetype_list mpeg

namespace eval mpeg {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		fas_fastdebug {mpeg::new_type $filename}
		upvar $current_env fas_env
		
		if { ![catch {set target [fas_get_value target -noe]}] } {
			if { $target == "html" } {
					return fashtml
			}
		}
		
		# When a mpeg is met, in what filetype will it be by default
		# translated ?
		return [binary::new_type fas_env $filename mpeg]
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
		return "[binary::get_title $filename]"
	}


	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename mpeg
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename mpeg
	}

	proc 2rrooll { current_env filename } {
		fas_fastdebug {mpeg::2rrooll $filename}
		upvar $current_env fas_env

		# movie length
		## using a shell script (tcl/utils/mplayer-time.sh) which only echoes
		## length if it was able to retrieve it. could also be empty or "0" !
		if { [catch {set time_to_play [exec ${::FAS_PROG_ROOT}/utils/mplayer-time.sh ${filename}]}]
			|| $time_to_play == ""
			|| $time_to_play == "0" } {
			fas_fastdebug {mpeg::2rrooll ${filename} - unable to get movie duration}
		} else {
			fas_fastdebug {mpeg::2rrooll ${filename} - movie length is $time_to_play}
			set fas_env(rrooll.time) $time_to_play
		}

		set fas_env(rrooll.command) "mpeg::2fashtml fas_env ${filename}"
		return "[2fashtml fas_env ${filename}]"
	}

	proc 2small { current_env filename } {
		upvar $current_env fas_env

		if [info exists fas_env(capture.position)] {
			set delay ${fas_env(capture.position)}
		} else {
			set delay 20
		}

		# take a snapshot of the movie
		## using a shell script
		if {[catch {set picfilename [exec ${::FAS_PROG_ROOT}/utils/mplayer-snapshot.sh ${filename} ${::ROOT}/any/snapshots/${filename}.png $delay]}]
			|| ${picfilename} == "" } {

			fas_fastdebug {mpeg::2small ${filename} - unable to have a picture of the video}
			set picfilename "${::ROOT}/any/snapshots/not_found.png"

		} else {
			fas_fastdebug {mpeg::2small ${filename} - capture taken successfully}
		}
		set fas_env(capture.filename) ${picfilename}

		# make a thumbnail from the snapshot
		## calling convert (ImageMagick) in a shell script
		if [catch {exec ${::FAS_PROG_ROOT}/utils/thumbnail.sh ${picfilename} "${picfilename}.mini.png" 100x100}] {
			set picfilename "${::ROOT}/any/snapshots/not_found.png"
		}

		# return the content of the pic filename
		# $picfilename.mini.png must exist !!!
		return [tiffg3::2small fas_env "${picfilename}.mini.png"]
	}

	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename mpeg $filename fas_env]
		fas_depend::set_dependency $real_filename file

		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env mpeg.template] } errStr] } {
			fas_display_error "mpeg::2fashtml - [translate "Problem getting template name"] mpeg.template<br>${errStr}" fas_env
		}

		fas_depend::set_dependency $template_name file

		if { [catch { atemt::read_file_template_or_cache "MPEG_TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "mpeg::2fashtml - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}
		# Preparing the variables
		# begin modif Xav
		#set export_filename $filename

		fas_debug "mpeg::2fashtml - filename is $filename"
		set export_filename [rm_root $filename]
		#set export_filename "[fashtml::to_right_url "fas:$filename" {} ""]$filename&target=html"
		fas_debug "mpeg::2fashtml - export_filename $export_filename"
		#set export_filename $real_filename
		# end modif Xav

		# translate the title of the frame
		atemt::atemt_set TITLE "[translate "MPEG FILE"] $export_filename"
		set icons_url [fas_name_and_dir::get_icons_dir]
		# We substitute the variables
		atemt::atemt_set MPEG_TEMPLATE -bl [atemt::atemt_subst -block RROOLL -block TITLE MPEG_TEMPLATE]

		# Here there is filename and dir to substitute
		set content [atemt::atemt_subst -end MPEG_TEMPLATE]

		# process fas: tags
		return "[fashtml::content2htmf fas_env $content \"\"]"
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
		binary::display mpeg video/mpeg $filename env
	}

    proc content { current_env filename } {
        upvar $current_env fas_env
        return [binary::content fas_env $filename mpeg]
	}

	proc mimetype { } {
		return "video/mpeg"
	}
}
