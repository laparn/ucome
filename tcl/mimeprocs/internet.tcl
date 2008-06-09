# extension for internet
set conf(extension.int) internet
set conf(extension.internet) internet

lappend filetype_list internet

#set INTERNET_DIR "${ROOT}/any/internet"


# And now all procedures for internet.
namespace eval internet {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES
	
	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES
	
	set DEBUG 1
	

	proc new_type { current_env filename } {
		upvar $current_env fas_env
		# This is the default answer
		set result domp
		
		# Now there may be other cases
		fas_debug "internet::new_type starting"
		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "internet::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
 		if { ![catch {set target [fas_get_value target -noe]}] } {
 			# we are in the standard case nothing to do
 			switch -exact -- $target {

 				pdf  {
 					set result fashtml
 					# No need to write it, but it is more clear so
 				}
 				htmf  {
 					set result fashtml
 					# No need to write it, but it is more clear so
 				}
 				fashtml {
 					set result fashtml
 				}
 				nomenu {
					#fas_debug_parray fas_env "internet::new_type fas_env before down_stage_env"
					down_stage_env fas_env "order.cgi_uservar." 
					#fas_debug_parray fas_env "internet::new_type fas_env after down_stage_env"
 					set result domp
 				}
				order {
					#fas_debug_parray fas_env "internet::new_type fas_env before down_stage_env"
					down_stage_env fas_env "order.cgi_uservar." 
					#fas_debug_parray fas_env "internet::new_type fas_env after down_stage_env"
					set result domp
				}
 			}
 		}
		fas_debug "internet::new_type end"
		return $result
	}

	proc init { } {
		#global INTERNET_DIR
		#set INTERNET_DIR [add_root "any/internet"]
	}
	
	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list comp]
	}

	# This procedure returns the list of important session variables for
	# this type of file
	# If this function is not defined, no one are important
	proc important_session_keys { } {
		# not any one
		return [list]
	}
	
	# Return the list of environment variables that are important
	# If this function is not defined, it is a final type that can
	# not be converted
	proc env { args } {
		set env_list ""
		lappend env_list [list "internet.tcl_dir"  "File with a css style sheet used in html files obtained after a text transformation." admin]
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 1
	}

	proc new { current_env current_conf args } {
		fas_debug "internet::new - env current_conf"
		upvar $current_env fas_env
		upvar $current_conf fas_conf
		# What to do ?
	}

	# this function returns 1 if $basename.comp or $basename.$subpage.comp exists
	proc exists { current_env filename } {
		upvar $current_env env
		global conf
		global _cgi_uservar
		#global INTERNET_DIR
		set INTERNET_DIR [add_root "any/internet"]

		fas_debug "internet::exists - $filename"

		#set real_filename [fas_name_and_dir::get_real_filename txt $filename env]
		set real_filename $filename
		if { ![regexp -nocase -- ".*?(\[^/\]+)\.int(?:ernet)?$" $real_filename trash basename]} {
			fas_display_error "internet::exists - Bad filename $filename" fas_env -f $filename
		}

		catch {unset index_page}
		if [info exists _cgi_uservar(subpage)] {
			set index_page $_cgi_uservar(subpage)
		} elseif [catch {fas_session::setsession multi_${basename}_index} index_page] {
			catch [unset index_page]
		}
		

		if [info exists index_page] {
			# see if $basename_files/$basename.$subpage.comp exists
			set comp_filename "${INTERNET_DIR}/last/${basename}_files/$basename.${index_page}.comp"
			return [file exists $comp_filename] 
			
		} else {
			set comp_filename "${INTERNET_DIR}/last/$basename.comp"
			return [file exists $comp_filename] 
		}
		return "0"
	}

	proc 2domp { current_env filename } {
		upvar $current_env env
		global conf
		global _cgi_uservar
		#global INTERNET_DIR
		set INTERNET_DIR [add_root "any/internet"]

		fas_debug "internet::2domp starting - $filename"
		#set real_filename [fas_name_and_dir::get_real_filename txt $filename env]
		set real_filename $filename

		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file
		
		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		if { ![regexp -nocase -- ".*?(\[^/\]+)\.int(?:ernet)?$" $real_filename trash basename]} {
			fas_display_error "internet::2domp - Bad filename $filename" fas_env -f $filename
		}

		 
		if [info exists _cgi_uservar(subpage)] {
			fas_debug "internet::2domp - subpage : ${_cgi_uservar(subpage)}" 
			# It is a subpage
			set index_page $_cgi_uservar(subpage)
			set comp_filename "${INTERNET_DIR}/last/${basename}_files/${basename}.${index_page}.comp"
			fas_depend::set_dependency $comp_filename file
			if [catch {set fdfile [open $comp_filename r]}] {
				fas_display_error "internet::2domp - Could not open [rm_root2 $comp_filename]" fas_env -f $filename
			}
			set cont [read $fdfile]
			close $fdfile
		} else {
			fas_debug "internet::2domp - subpage : none"
			#It is not a subpage, but it may be an index or a single comp
			set index_filename [file join ${INTERNET_DIR} last ${basename}.html]
			if { [file readable $index_filename] } {
				# I take it
				fas_depend::set_dependency $index_filename file
				if [catch {set fdfile [open $index_filename r]}] {
					fas_display_error "internet::2domp - Could not open $index_filename" fas_env -f $filename
				}
				set tmp(content.content) [read $fdfile]
				close $fdfile
				set cont [array get tmp]
			} else {
				set comp_filename "${INTERNET_DIR}/last/$basename.comp"
		
				fas_depend::set_dependency $comp_filename file
				if [catch {set fdfile [open $comp_filename r]}] {
					fas_display_error "internet::2domp - Could not open $comp_filename" fas_env -f $filename
				}
				set cont [read $fdfile]
				close $fdfile
			}
		}
		
		fas_debug "internet::2domp end"
		
		return $cont
	}

	
	proc get_title { filename } {
		# The title is the first line of the file
		set title ""
		if { ![catch {open $filename} fid] } {
			set title [gets $fid]
			close $fid
		}
		return $title
	}
	
	proc content_display { current_env content } {
		upvar $current_env env
		fas_debug "internet::content_display start"
		htmf::content_display env $content
		fas_debug "internet::content_display end"
	}
	
	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		fas_debug "internet::display start"
		# it is a file
		if { [catch {open $filename} fid] } {
			fas_display_error "txt::display - could not open $filename" -file $filename
		} else {
			set content [read $fid]
			close $fid
			htmf::content_display fas_env "<pre>$content</pre>"
		}
		fas_debug "internet::display end"
	}
		
	proc copy_archive { current_env filename dest_dirname } {
		upvar $current_env env
		set INTERNET_DIR [add_root "any/internet"]
		#global INTERNET_DIR

		fas_debug "internet::copy_archive - $current_env $filename $dest_dirname"
		
		# first copy internet file 
		order::simple_copy_archive env $filename $dest_dirname

		# get basename
		if { ![regexp -nocase -- ".*?(\[^/\]+)\.int(?:ernet)?$" $filename trash basename]} {
			log::log warning "Bad filename $filename"
		} else {
			set comp_filename "${INTERNET_DIR}/last/$basename.comp"
			order::simple_copy_archive env $comp_filename $dest_dirname
			
			set internet_dirname "${INTERNET_DIR}/last/${basename}_files"
			dir::copy_archive env $internet_dirname $dest_dirname
		
			foreach file [glob -nocomplain -tail -directory ${INTERNET_DIR}/last/${basename}_files/ * ] {
				order::simple_copy_archive env "${INTERNET_DIR}/last/${basename}_files/$file" $dest_dirname
			}
		}
	}


}
