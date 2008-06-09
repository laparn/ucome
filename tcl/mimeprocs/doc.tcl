set conf(extension.doc) doc

lappend filetype_list doc

namespace eval doc {

	set local_conf(doc.fas-converter) /usr/local/bin/fas-converter

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		# When a doc is met, in what filetype will it be by default
		# translated ?
		set result tmpl
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
		return $result
	}

	proc new_type_list { } {
		return [list tmpl fashtml]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	proc env { args } {
		return ""
	}

	proc mimetype { } {
		return "application/msword"
	}

	proc get_title { filename } {
		return "[binary::get_title $filename]"
	}

	proc content_display { current_env content } {
		puts "Content-type: application/msword\n"
		puts "$content"
	}
	
	# the MS/Word document will be converted into html, with a
	# 3rt party tool called FAS-Converter
	proc 2fashtml { current_env filename } {
		upvar $current_env env
		global conf
		variable local_conf

		set real_filename [fas_name_and_dir::get_real_filename doc $filename env]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		# fas_depend::set_dependency $filename env

		fas_debug "doc::2fashtml"

		# we convert the .doc file into HTML
		# I would prefer a xxxx.doc.html name
		set realhtml_filename "[ file rootname $real_filename ].html"
		if { [catch { exec $local_conf(doc.fas-converter) -q -f $real_filename $realhtml_filename } error] } {
			if { [catch {set content [get_autocache_content $real_filename] } ] } {
				set content "doc::2fashtml - [translate "problem while processing"] $real_filename <BR>[translate "fas-converter is perhaps not yet set up"]<br>$error"
			}
		} else {

			# now we have a <filename>.html file and maybe a <filename>_fichiers directory
			# in the directory of the .doc
			# we just return the content of the .html file
			set fid [open $realhtml_filename]
			if { [catch { set content [read $fid]} error] } {
				set content "doc::2fashtml - [translate "problem while processing"] $real_filename<br>$error"
				return ""
			}
 			close $fid
		}
		
		return $content
	}

	# the MS/Word document will be converted into txt, with a
	# 3rt party tool called FAS-Converter
	proc 2txt4index { current_env filename } {
		upvar $current_env env
		global conf
		variable local_conf

		set real_filename [fas_name_and_dir::get_real_filename doc $filename env]

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		fas_debug "doc::2txt4index"
	    
	        if { [catch { set fid [eval open \"|$local_conf(doc.fas-converter) -o txt $real_filename stdout \"] } ] } {
		    fas_display_error "doc::2txt4index - [translate "problem while processing"] $real_filename<br>$error" -file $filename
 		}
		    
		
 		if { [catch { set content [read $fid]} error] } {
 			fas_display_error "doc::2txt4index - [translate "problem while processing"] $real_filename<br>$error" -file $filename
 			return ""
 		}
 		close $fid
		
		return $content
	}

	proc 2tmpl { current_env args } {
		fas_debug "doc::2tmpl - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}

	proc display { current_env filename  } {
		# A procedure for just sending the output on the
		# stdout.
		upvar $current_env env
	
		# it is a file
		if { [catch {set real_filename [fas_name_and_dir::get_real_filename doc $filename env ] } ] } {
			# problem while searching for the real file
			fas_display_error "doc::display - [translate "Problem while searching for"] $filename" env -file $filename
		} else {
			# Now sending the output
			set fileid [open $real_filename]
			puts stdout "Content-type: application/msword\n"

			# Outputing the file :
			puts stdout [read $fileid]
			catch { close $fileid }
		}
	}
}
