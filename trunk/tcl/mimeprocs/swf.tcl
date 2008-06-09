set conf(extension.swf) swf
lappend filetype_list swf

namespace eval swf {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		fas_fastdebug {swf::new_type $filename}
		upvar $current_env fas_env
		
		if { ![catch {set target [fas_get_value target -noe]}] } {
			switch -exact -- $target {
				ori {
					set result txt
					return ""
				}
				rrooll -
				rool {
					fas_debug_parray fas_env "swf::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "swf::new_type fas_env after down_stage_env with rool"
					unset ::_cgi_uservar(target)
					return comp
				}
				rrooll1 -
				rool1 {
					fas_debug_parray fas_env "swf::new_type fas_env before down_stage_env with rrooll1"
					down_stage_env fas_env "rrooll1.cgi_uservar."
					fas_debug_parray fas_env "swf::new_type fas_env after down_stage_env with rrooll1"
					unset ::_cgi_uservar(target)
					return comp	
				}
				rrooll2 -
				rool2 {
					fas_debug_parray fas_env "swf::new_type fas_env before down_stage_env with rrooll2"
					down_stage_env fas_env "rrooll2.cgi_uservar."
					fas_debug_parray fas_env "swf::new_type fas_env after down_stage_env with rrooll2"
					unset ::_cgi_uservar(target)
					return comp
				}
				rrooll3 -
				rool3 {
					fas_debug_parray fas_env "swf::new_type fas_env before down_stage_env with rrooll3"
					down_stage_env fas_env "rrooll3.cgi_uservar."
					fas_debug_parray fas_env "swf::new_type fas_env after down_stage_env with rrooll3"
					unset ::_cgi_uservar(target)
					return comp
				}
			}
		}
		
		# When an swf is met, in what filetype will it be by default
		# translated ?
		return [binary::new_type fas_env $filename swf]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	
	proc env { args } {
		set env_list ""
		lappend env_list [list "flash.bgcolor" "Background color for flash when displayed in an html file (rool situation)" user]
		return $env_list
	}

	proc get_title { filename } {
		return "[binary::get_title $filename]"
	}


	# Now all procedures for the actions
	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename swf
	}

	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		binary::2edit fas_env $filename swf
	}

	proc 2comp { current_env args } {
		fas_debug "swf::2comp - $args"
		upvar $current_env fas_env
		global ::_cgi_uservar
		set tmp_content "[extract_body [eval 2fashtml fas_env $args ]]"
		if { [info exists ::_cgi_uservar(message)] } {
			set tmp_content "<h1>$::_cgi_uservar(message)</h1>$tmp_content"
		}
		set tmp(content.content) $tmp_content
		return "[array get tmp]"
	}

	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename swf $filename fas_env]
		if { [catch { set template_name [fas_name_and_dir::get_template_name fas_env swf.template] } errStr] } {
			fas_display_error "swf::2fashtml - [translate "Problem getting template name"] swf.template<br>${errStr}" fas_env
		}

		fas_depend::set_dependency $template_name file
		if { [catch { atemt::read_file_template_or_cache "SWF_TEMPLATE" "$template_name" } errStr ] } {
			fas_display_error "swf::2fashtml - [translate "Problem while opening template "] ${template_name}<br>${errStr}" fas_env -f $filename
		}

		# Preparing the variables
		fas_debug "swf::2fashtml - filename is $filename"
		global FAS_VIEW_CGI
		set export_filename [rm_root $filename]
		#set export_filename "[fashtml::to_right_url "fas:$filename" {} ""]$filename&target=html"
		fas_debug "swf::2fashtml - export_filename $export_filename"
		#set export_filename $real_filename

		# translate the title of the frame
		atemt::atemt_set TITLE "[translate "FLASH FILE"] $export_filename "

		set icons_url [fas_name_and_dir::get_icons_dir]
		# I create a variable for the background_color
		set bgcolor "#ffffff"
		if { [info exists fas_env(flash.bgcolor)] } {
			set bgcolor  $fas_env(flash.bgcolor)
		}
		

		# We substitute the variables
		atemt::atemt_set SWF_TEMPLATE -bl [atemt::atemt_subst -block CONTENT -block TITLE SWF_TEMPLATE]

		# Here there is filename and dir to substitute
		set content [atemt::atemt_subst -end SWF_TEMPLATE]

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
		binary::display swf application/x-shockwave-flash $filename env
	}

	proc content { current_env filename } {
        upvar $current_env fas_env
        return [binary::content fas_env $filename swf]
	}
	
	proc mimetype { } {
		return "application/x-shockwave-flash"
	}
}
