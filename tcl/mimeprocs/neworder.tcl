# When an order file is met, then we try to get the corresponding file
# in html and add the javascript for asking for a new order the next time
lappend filetype_list order

package require log

# I must put the following variable definition in the
# function that uses it. So search it, if you wish to modify it
#set conf(order_rrooll_url) "${FAS_VIEW_URL}?file="
set conf(order_onLoad) ""
set conf(order_custom_javascript) ""
set conf(order_javascript) ""

# So it will work in the following way :
#  * when I ask for the display of a directory which is of order type,
#    I look if there is a session variable element_number. If there is not
#    I create one with number 0.
#  * Then I take the list of files [0-9]+.order in the directory,
#  * I order them by alphabetical order and I ask for the display
#    of the corresponding file. If I am over the length of the list
#    I obviously jump to the file 0. 
#  * For displaying, I :
#    * get the file,
#    * add javascript for rolling + javascript for asking for the next
#      page + speed parameters.
#  * At the end of the display I increase of 1 the nber of the file to display
#    and I put it in the session variables.
#
#
# An order file will be a file with the potentially following values defined
# filename : name of a file to display
# or url : url of the file to display (=> images must be cached)
# start_speed : speed at beginning of a window
# roll_speed : nber of lines jumped each time
# end_speed : time at the end of the file before jumping to the next page
#
#
# WARNING html or fashtml ????????????
#set conf(newtype.order) html
# extension for order
set conf(extension.order) order
set conf(extension.ord) order
set conf(extension.or) order

#source "${FAS_PROG_ROOT}/internet/readconf.tcl"

# And now all procedures for order
namespace eval order {
# Default value for *.order
	variable default_var
	set default_var(condition) "none"
	set default_var(start_delay) "1000"
	set default_var(end_delay) "1000"
	set default_var(line_jump_delay) "500"
	set default_var(page) ""
	set default_var(file) ""
	set default_var(multirange_start) "0"
	set default_var(multirange_stop) "50"
	set default_var(time) "00:00"
	set default_var(timerange_start) "00:00"
	set default_var(timerange_stop) "00:00"
	set default_var(type) "page"
	set default_var(comment) ""
	
	variable op_description
	set op_description(type) "Type de la section."
	set op_description(condition) "Condition devant etre appliqu� � la section"
	set op_description(start_delay) "Latence entre l'affichage de la page et le d�but du d�roulement exprim�e en millisecondes."
	set op_description(end_delay) "Latence entre la fin du d�roulement de la page et le chargement de la page suivante exprim�e en milliseconde"
	set op_description(line_jump_delay) "Vitesse de d�filement d'une page. Cette valeur correspond au temps en millisecodne entre chaque saut de ligne"
	set op_description(page) "Fichier � afficher"
	set op_description(file) "Fichier .order � parcourir"
	set op_description(multirange_start) "Num�ro du premier contenu � afficher."
	set op_description(multirange_stop) "Num�ro du dernier contenu � afficher."
	set op_description(time) "Heure d'affichage de la section (format hh:mm)."
	set op_description(timerange_start) "Heure de d�but d'affichage de la section (format hh:mm)"
	set op_description(timerange_stop) "Heure de fin d'affichage de la section (format hh:mm)"
	set op_description(comment) ""
	
	variable op_bloc
	set op_bloc(page) "OPTION_SEC"
	set op_bloc(file) "OPTION_SEC"
	set op_bloc(multirange_start) "OPTION_SEC"
	set op_bloc(multirange_stop) "OPTION_SEC"
	set op_bloc(time) "OPTION_SEC"
	set op_bloc(timerange_start) "OPTION_SEC"
	set op_bloc(timerange_stop) "OPTION_SEC"
	set op_bloc(type) "OPTION_SEC"
	
	variable op_name
	set op_name(page) "Page"
	set op_name(file) "Fichier order"
	set op_name(multirange_start) "Numero du premier fichier internet multiple"
	set op_name(multirange_stop) "Numero du dernier fichier internet multiple"
	set op_name(time) "Heure"
	set op_name(timerange_start) "Heure de d�but"
	set op_name(timerange_stop) "Heure de fin"
	set op_name(type) "??"
	
	variable op_typecond_description
	set op_typecond_description(page) "Page unique"
	set op_typecond_description(file) "Fichier order"
	set op_typecond_description(true) "Toujours vrai"
	set op_typecond_description(false) "Toujours faux"
	set op_typecond_description(none) "Pas de condition"
	set op_typecond_description(time) "Heure pr�cise"
	set op_typecond_description(timerange) "Intervale de temps"
	set op_typecond_description(hour) "A chaque nouvelle heure"
	
	
	variable top_order_flag
	set top_order_flag 1

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	# Here, the new_type procedure takes its whole interest
	# the goal is here to get the real file and not always
	# the end html
	proc new_type { current_env filename } {
		fas_debug "order::new_type $filename"

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				if { $action == "edit_form" } {
					if { [fas_cgi_exists store_name] } {
						set result final
						return "edit"
					}
				}
				# there is an action. Is it done or not
				fas_debug "order::new_type - action -> $action , action::done -> [set ${action}::done]"
				if { [set ${action}::done ] == 0 } {
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		if { ![catch {set target [fas_get_value target]}] } {
			# we are in the standard case nothing to do
                        fas_debug "order::new_type - target -> $target"
			switch -exact -- $target {
				mpeg21 {
                                        fas_debug "order::new_type - returning mpeg21"
					return "mpeg21"
				}
			}
		}
		# First get the content of the file
		#read_env $filename order
		#set result fashtml
		set result ""
		#fas_debug "order::new_type - file - $order(filename) -> $result"
		fas_debug "order::new_type - result is -> $result"
		return $result
	}
	# Procedure used to initialise the variables when restarting a display
	proc init { } {
		variable top_order_flag
		set top_order_flag 1
	}
	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	proc get_title { filename } {
		# The title is the first line of the file
		set title "Order file [rm_root $filename]"
	}

                # Return the list of environment variables that are important
        # If this function is not defined, it is a final type that can
        # not be converted
        proc env { args } {
                set env_list ""
                return $env_list
        }
        
	# begin modif Xav
	## get the type of the section
	## tries to be "error-proof" ("user-proof" ??)
	### WARNING : will modify order_conf
	###		--> removes bad section entries for $section
	###		--> add correct entry
	proc get_section { current_env section order_conf } {
		upvar 1 ${current_env} env
		upvar 1 ${order_conf} ordconf

		fas_debug "order::get_section section->$section order_conf->"
		fas_debug_parray ordconf

		###
		# get the section type if present
		set stype ""
		if [info exists ordconf(${section}.type)] {
			set stype $ordconf(${section}.type)
		}
		fas_fastdebug {order::get_section - section type after 1st iteration is \'${stype}\'}

		###
		# get the filename
		set sfile ""
		catch {set sfile [get_section_file $section ordconf ${stype}]}

		###
		# determine the section type (2nd iteration)
		global conf
		if { ${sfile} == "" } {
			## better use a debug message rather than raising an error
			## so that we can keep going !
			fas_debug "order::get_section $section - unable to get section parameters... sorry!"
			#fas_display_error "order::get_section - unable to get section parameters... sorry!" env
		} else {

			# here we try to eventually fix syntax errors
			# like "page = myfile.order" or "file = myfile.jpg"
			if { ! [catch {set filetype [guess_filetype ${sfile} conf env]}] } {
				## if a list of files is given as parameters I believe that
				## an error will be raised by guess_filetype and then catched
				switch $filetype {
					"order" {
						if { $stype != "file" } {
							set stype "file"
						}
					}
					default {
						#if { $stype == "" } {
							set stype "page"
						#}
					}
				}

				## very experimental ;o)
			} else {
				set stype "page"
			}
		}

		###
		# fix the conf(order) entry
		if [info exists ordconf(order)] {
			fas_fastdebug "order::get_section - section $section - order before fix : $ordconf(order)"

			# should I delete it or add the .type entry ?
			# currently deletes
			set i [lsearch -glob $ordconf(order) "${section}.type"]
			set ordconf(order) [lreplace $ordconf(order) $i $i]

			# replace the bad entry with the correct one
			set i [lsearch -glob $ordconf(order) "${section}.*"]
			set ordconf(order) [lreplace $ordconf(order) $i $i "${section}.${stype}"]

			fas_fastdebug "order::get_section - section $section - order after fix : $ordconf(order)"
		}

		fas_fastdebug {order::get_section - section type after 2nd iteration is \'${stype}\'}

		###
		# and finally set the correct values
		set ordconf(${section}.type) ${stype}
		set ordconf(${section}.${stype}) ${sfile}
	}

	# try to obtain the filename
	## should not be used outside of the order namespace !
	### WARNING : will modify order_conf
	proc get_section_file { section order_conf section_type } {
		upvar 1 ${order_conf} ordconf

		fas_debug "order::get_section_file section->$section section_type->$section_type order_conf->"
		fas_debug_parray ordconf

		###
		# standard old-school case. we got something like that :
		##								[ x ]
		##								type = mytype
		##								mytype = path
		if { $section_type != "" } {
			if [info exists ordconf(${section}.${section_type})] {
				return $ordconf(${section}.${section_type})
			} else {
				## damned ! we must take another way...
				return [get_section_file $section ordconf ""]
			}

		###
		# new, flexible case. we only have : 
		##								[ x ]
		##								any = path
		# where any could be anything in testlist
 		# we try to recover the data we need and to fix errors.
		} else {
			set testlist [list "page" "file" "fichier" "order" "internet" "rool" "list" "multi_file" "src" "url" "comp"]
			return [clean_section ${section} ordconf testlist]
		}
	}

	# clean order_conf --> removes bad entries
	### WARNING : will modify order_conf
	proc clean_section { section order_conf section_type_list } {
		upvar 1 ${order_conf} ordconf
		upvar 1 ${section_type_list} testlist

		set sfile ""
		foreach section_type $testlist {
			if [info exists ordconf(${section}.${section_type})] {
				set sfile $ordconf(${section}.${section_type})
				unset ordconf(${section}.${section_type})
			}
		}

		if { $sfile != "" } {
			fas_fastdebug {order::clean_section - file is $sfile}
			return $sfile
		} else {
			fas_fastdebug {order::clean_section - error : unable to find filename!}
			return ""
		}
	}
	# end modif Xav

	proc get_order_file_list { filename } {
		fas_fastdebug {neworder::get_order_file_list - entering}
		variable default_var
		# Basically 2 possibilities
		# From the file or from the graphical interface
		#global _cgi_uservar
		# fas_debug_parray _cgi_uservar " _cgi_uservar "
		set full_lol ""
		if { ![fas_cgi_exists show] && ![fas_cgi_exists store_name] }  {
			# we want to load the file from the order file
			if [file readable "$filename"] {
				if [catch { ReadConf "$filename" order_conf}] {
					fas_display_error "order::get_order_file_list - Error while loading $filename" fas_env -f $filename
				}
			}
			# I construct a lol with all arguments
			# There will be : included (it is in), the order, the filename,
			# the start_delay, end_delay, scroll_speed, flag_is_order or not
			# flag_is_order : if it is an order file 1, else single page 0
			set counter 0
			set in_lol [list [list file select_on shortname order.start_delay order.end_delay order.line_jump_delay order.counter]]
			foreach section [OrderedGetSectionList order_conf] {
				set current_list ""
				GetItemFromSection order_conf $section res
				if { [info exists res(file)] } {
					set file $res(file)
					set shortname  $file 
					lappend current_list $file 1 $shortname
					foreach prop [list start_delay end_delay line_jump_delay] {
						if { [info exists res($prop)] } {
							lappend current_list $res($prop)
						} else {
							lappend current_list $default_var($prop)
						}
					}
					# It is in the order list, I mark it
					lappend current_list $counter
					lappend in_lol $current_list
					incr counter	
				}
				# else , I ignore the section
			}
			fas_debug "neworder::get_order_file_list : in_lol => $in_lol" 
			# Now I add to the list the files that are NOT in the current
			# order file
			# I will take them from the session variable order.candidate_list
			set out_lol [list [list file select_on shortname]]
			if { [catch {::fas_session::setsession order.candidate_list} candidate_list] } {
				# nothing
			} else {
				fas_fastdebug {neworder::get_order_file_list candidate_list from session is : $candidate_list}
				foreach file $candidate_list {
					set shortname $file
					set current_list [list $file 0 $shortname]
					lappend out_lol $current_list
					incr counter
				}
			}
			fas_debug "neworder::get_order_file_list : out_lol after getting order.candidate_list => $out_lol"
			set full_lol [list $in_lol $out_lol]
		} else {
			# we take all values from the imported cgi variables
			set full_lol [import_lol]
		}
		return $full_lol
	}
	
	# Import all values for knowing the files that are
	# in the order file, and the files that are out.
	proc import_lol { } {
		variable default_var
		fas_fastdebug {neworder::import_lol - entering}
		set counter 0
		set in_lol [list [list file select_on shortname order.start_delay order.end_delay order.line_jump_delay order.counter]]
		set out_lol [list [list file select_on shortname]]
		set max_in_counter 0
		while { [fas_cgi_exists file_on$counter] } {
			fas_fastdebug {neworder::import_lol : found checkbox_on$counter}
			if [fas_cgi_exists checkbox_on$counter] {
				fas_fastdebug {neworder::import_lol : checkbox_on$counter is 1}
				# It is in the in_list
				set current_list [list]
				set current_check 1
				# I should check if the counter value is really a number
				if { [fas_cgi_exists file_on$counter] } {
					set current_file [fas_cgi_get file_on$counter]
					set current_list [list $current_file 1 $current_file]
					foreach argument [list start_delay end_delay line_jump_delay counter] {
						if { [fas_cgi_exists order.${argument}.${counter}] } {
							set current_${argument} [fas_cgi_get order.${argument}.${counter}]
						} else {
							set current_${argument} ""
						}
						lappend current_list [set current_${argument}]
					}
					# If the counter is not an integer, I replace it with ""
					if { ![string is integer $current_counter] } {
						set current_counter ""
					}
					# Checking for the max number for the counter
					# I need that for after, for creating a counter
					# for the file coming from the candidate list
					if { $current_counter != "" } {
						if { $current_counter > $max_in_counter } {
							set max_in_counter $current_counter
						}
					}
					lappend in_lol $current_list
					fas_fastdebug {neworder::import_lol - putting $current_list in in_lol}
				} else {
					fas_fastdebug {neworder::import_in_lol - strange found checkbox_on$counter but no file_on$counter}
				}
			} else {
				fas_fastdebug {neworder::import_lol : checkbox_on$counter is 0}
				# Not in the in_list
				# then out.
				if { [fas_cgi_exists file_on$counter] } {
					set current_file [fas_cgi_get file_on$counter]
					lappend out_lol [list $current_file 0 $current_file]
					fas_fastdebug {neworder::import_lol : put $current_file in out_lol}
				}
			}
			incr counter
		}
		# and now taking in charge the out_lol
		fas_fastdebug {neworder::import_lol - checking checkbox$counter}
		set counter 0
		while { [fas_cgi_exists file$counter] } {
			fas_fastdebug {neworder::import_lol - checkbox$counter exists}
			if [fas_cgi_exists checkbox$counter] {
				fas_fastdebug {neworder::import_lol - checkbox$counter is 1}
				# It is in the in_list
				set current_list [list]
				set current_check 1
				if { [fas_cgi_exists file$counter] } {
					set current_file [fas_cgi_get file$counter]
					incr max_in_counter
					lappend in_lol [list $current_file 1 $current_file $default_var(start_delay) $default_var(end_delay) $default_var(line_jump_delay) $max_in_counter]
					fas_fastdebug {neworder::import_lol - putting $current_file in in_lol}
				}
			} else {
				fas_fastdebug {neworder::import_lol - checking  file$counter}
				if { [fas_cgi_exists file$counter] } {
					set current_file [fas_cgi_get file$counter]
					lappend out_lol [list $current_file 0 $current_file]
					fas_fastdebug {neworder::import_lol - putting $current_file in out_lol as file$counter exists}
				}
			}
			incr counter
		}
		fas_fastdebug {neworder::import_lol - final out_lol is $out_lol}
		return [list [reorder_in_lol $in_lol] $out_lol]
	}

	# Ordering the in_lol in fonction of the order index
	proc reorder_in_lol { in_lol } {
		set usefull_lol [lrange $in_lol 1 end]
		set final_lol [lsort -integer -index 6 $usefull_lol]
		set start_list [lindex $in_lol 0]
		set final_lol [linsert $final_lol 0 $start_list]
		fas_fastdebug {neworder::reorder_in_lol - reordered in_lol => $final_lol}
		return $final_lol
	}
		
	proc 2edit_form { current_env filename } {
		fas_debug "order::2edit_form - entering"
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		fas_depend::set_dependency 1 always

		set all_order_file_lol [get_order_file_list $filename ]
		# Now I must get an ordered list of files in the order_file
		# Then I must get the list of files out of the order_file
		set in_lol [lindex $all_order_file_lol 0]
		set out_lol [lindex $all_order_file_lol 1]
		# Now I load the template
		# Then I go from list to list of the order_file, and I display it
		set inmenu_html [extract_body [::dir::display_file_lol $in_lol fas_env -display [list select_on shortname order.start_delay order.end_delay order.line_jump_delay order.counter] -title [translate "Files in order file"] -noadd 1 -form 0 -i "table0"]]
		fas_fastdebug {order::2edit_form - inmenu_html => $inmenu_html}
		# After that I display the files out of order
		set outmenu_html [extract_body [::dir::display_file_lol $out_lol fas_env -display [list select shortname] -title [translate "Candidate files"] -noadd 1 -form 0 -i "table1"]]
		fas_fastdebug {order::2edit_form - outmenu_html => $outmenu_html}
		# Load the template
		set dfl_template_name [fas_name_and_dir::get_template_name fas_env "edit_form.order.template"]
		atemt::read_file_template_or_cache "ORDER_EDIT_FORM_TEMPLATE" "$dfl_template_name" 
		fas_depend::set_dependency $dfl_template_name file
		# Getting the default icons_url path
		set icons_url [fas_name_and_dir::get_icons_dir]
		set export_filename [rm_root $filename]

		# put in the 2 sections the html
		atemt::atemt_set INMENU $inmenu_html
		atemt::atemt_set OUTMENU $outmenu_html

		# finish it
		atemt::atemt_set FORM -bl [atemt::atemt_subst -block INMENU -block OUTMENU FORM]
		atemt::atemt_set ORDER_EDIT_FORM_TEMPLATE -bl [atemt::atemt_subst -block FORM ORDER_EDIT_FORM_TEMPLATE]
		return [atemt::atemt_subst -end ORDER_EDIT_FORM_TEMPLATE]
	}

#	proc 2edit_form { current_env filename } {
#		fas_debug "order::2edit_form $filename"
#
#		upvar $current_env fas_env
#		global FAS_VIEW_CGI
#		variable default_var
#		variable op_description
#		variable op_typecond_description
#		global _cgi_uservar
#		variable local_conf
#
#		set export_filename [rm_root $filename]
#		set icons_url [fas_name_and_dir::get_icons_dir]
#		set dir [rm_root [file dirname $filename]]
#		regexp "(?:.*/)?(\[^/\]+)\.order" $filename trash basename
#
#		# Then the dependencies
#		fas_depend::set_dependency $filename always
#
#		# Get the modified order_conf in session or get it from the file
#		if [info exists _cgi_uservar(reload_file)] {
#			set reload_file $_cgi_uservar(reload_file)
#		} else {
#			set reload_file 0
#		}
#		
#		if [catch {fas_session::setsession ${basename}_modify } modify] {
#			set modify 0
#		}
#
#		if { $modify == 0 || $reload_file == 1 } {
#			# Read order file
#			if [file readable "$filename"] {
#				if [catch { ReadConf "$filename" order_conf}] {
#					fas_display_error "order::2edit_form - Error while loading $filename" fas_env -f $filename
#				}
#			}
#			# and set session variable with the order file
#			fas_session::setsession ${basename}_order_conf [array get order_conf]
#		} else {
#			if [catch {fas_session::setsession ${basename}_order_conf} array_order_conf] {
#				fas_display_error "order::2edit_form - Error while loading conf"
#			}
#			array set order_conf $array_order_conf
#			fas_session::setsession ${basename}_modify 1
#		}
#		
#		# edit a entiere file or only a section
#		set edit_section 0
#		if [info exists _cgi_uservar(section_name)] {
#			set section_name $_cgi_uservar(section_name)
#			foreach section [OrderedGetSectionList order_conf] {
#				if { $section == $section_name } {
#					set edit_section 1
#					break
#				}
#			}
#		}
#		
#		if { $edit_section != 1 } {
#			# then edit entire file
#
#			# Loading the template
#			set template_name [fas_name_and_dir::get_template_name fas_env edit_form.order.template]
#			fas_depend::set_dependency ${template_name} file
#
#			fas_debug "order::2edit_form - template name is $template_name"
#
#			if [catch {atemt::read_file_template_or_cache "EDIT_TEMPLATE" "${template_name}"} errmsg] {
#				fas_debug "order::2edit_form - unable to load template ($errmsg)"
#			} else {
#				fas_debug "order::2edit_form - template file loaded successfully"
#			}
#			# Then I print a template
#
#			atemt::atemt_set TITLE "[translate "Editing page "] ${filename}"
#
#			catch {fas_session::unsetsession ${basename}_section_order_conf}
#
#			#		atemt::atemt_set FORM ""
#			set list_sections [OrderedGetSectionList order_conf]
#			fas_fastdebug {order::2edit_form - sections to process are \'$list_sections\'}
#			foreach section ${list_sections} {
#				# set variable for template
#				fas_fastdebug {order::2edit_form - processing section \'$section\' with edit_section=$edit_section}
#				set section_name $section
#
#				# modif Xav : this is done later
#				#if { ![info exists order_conf($section.type)]} {
#				#	fas_display_error "order::2edit_form - No type option in section #$section"
#				#} else {
#				#	set section_type $order_conf($section.type)
#				#}
#
#				# AL : 25/12/2005
#				# I do not need the comment below
#				#if [info exists order_conf(${section}.comment)] {
#				#	set option_value $order_conf(${section}.comment)
#				#} else {
#				#	set option_value $default_var(comment)
#				#}
#				#set option_name "Commentaires"
#				#set option_description $op_description(comment)
#				#set option_form_name "option_comment"
#				#atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -no OPTION_SEC OPTION_PRIM]
#				#atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM_ENTRY SECTION]
#
#				# first the Type option and his options
#				set option_name "Type"
#				set option_description $op_description(type)
#
#				# begin modif Xav
#				if [catch {get_section fas_env $section order_conf} msg] {
#					fas_fastdebug {order::2edit_form - error encountered in get_section call with section \'$section\'}
#					## better use a debug message rather than raising an error
#					## so that we can keep going !
#					fas_debug "order::2edit_form - unable to get section (message is \'$msg\')"
#					#fas_display_error "order::2edit_form - unable to get section (message is \'$msg\')" fas_env
#				} else {
#					set section_type $order_conf(${section}.type)
#					set section_file $order_conf(${section}.${section_type})
#					set uri $section_file
#					set start_time ""
#					set end_time ""
#					set rooll_speed ""
#
#					set option_value $section_type
#					set option_sec_value $section_file
#					fas_fastdebug {order::2edit_form - section \'$section\' is of type $section_type, file to display is $section_file}
#					#atemt::atemt_set OPTION_PRIMN -bl [atemt::atemt_subst -insert -block OPTION_PRIM SECTION]
#
#					switch $section_type {
#						"page" {
#							set option_sec_name "Page"
#							set option_value "Page unique"
#							set option_sec_description $op_description(page)
#							# modif Xav : this is done earlier
#							#if [info exists order_conf(${section}.page)] {
#							#	set option_sec_value $order_conf(${section}.page)
#							#} else {
#							#	set option_sec_value $default_var(page)
#							#}
#							atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM]
#						}
#						"file" {
#							set option_sec_name "Fichier .order"
#							set option_value "Fichier .order"
#							set option_sec_description $op_description(file)
#							# modif Xav : this is done earlier
#							#if [info exists order_conf(${section}.file)] {
#							#	set option_sec_value $order_conf(${section}.file)
#							#} else {
#							#	set option_sec_value $default_var(file)
#							#}
#							atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM]
#						}
#						# "list" {
#						#	set option_sec_name "Liste de Page"
#						#	set option_value "Liste des pages"
#						#	set option_sec_description $op_description(order)
#						#	# modif Xav : this is done earlier
#						#	#if [info exists order_conf(${section}.order)] {
#						#	#	set option_sec_value $order_conf(${section}.order)
#						#	#} else {
#						#	#	set option_sec_value $default_var(order)
#						#	#}
#						#	atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM]
#						#}
#						# "multi" {
#						#	set option_sec_name "Page internet multiple"
#						#	set option_value "Page internet multiple"
#						#	set option_sec_description $op_description(multi_file)
#						#	# modif Xav : this is done earlier
#						#	#if [info exists order_conf(${section}.multi_file)] {
#						#	#	set option_sec_value $order_conf(${section}.multi_file)
#						#	#} else {
#						#	#	set option_sec_value $default_var(multi_file)
#						#	#}
#						#	atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM]
#						#	#					atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM_ENTRY]
#
#						#	set option_sec_name "Debut des pages multi"
#						#	set option_sec_description $op_description(multirange_start)
#						#	if [info exists order_conf(${section}.multirange_start)] {
#						#		set option_sec_value $order_conf(${section}.multirange_start)
#						#	} else {
#						#		set option_sec_value $default_var(multirange_start)
#						#	}
#						#	atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM_ENTRY]
#						#
#						#	set option_sec_name "Fin des pages multi"
#						#	set option_sec_description $op_description(multirange_stop)
#						#	if [info exists order_conf(${section}.multirange_stop)] {
#						#		set option_sec_value $order_conf(${section}.multirange_stop)
#						#	} else {
#						#		set option_sec_value $default_var(multirange_stop)
#						#	}
#						#	atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM_ENTRY]
#
#						#}
#
#
#					}
#
#					atemt::atemt_set EDIT_TEMPLATE -bl [atemt::atemt_subst -insert -block FORM EDIT_TEMPLATE]
#
#					# the condition option
#					if [info exists order_conf(${section}.condition)] {
#						set option_value $order_conf(${section}.condition)
#					} else {
#						set option_value $default_var(condition)
#					}
#					set option_name "Condition"
#					set option_description $op_description(condition)
#
#					switch $option_value {
#						"none" -
#						"true" -
#						"false" -
#						"hour" {
#							atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -no OPTION_SEC OPTION_PRIM]
#						}
#
#						"time" {
#							if [info exists order_conf(${section}.time)] {
#								set option_sec_value $order_conf(${section}.time)
#								if [catch {clock scan $option_sec_value} error ] {
#									fas_display_error "order::2edit_form - unable to convert time in section $section" fas_env
#								}
#							} else {
#								set option_sec_value $default_var(time)
#							}
#							set option_sec_name "Heure d'affichage"
#							set option_sec_description $op_description(time)
#							atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM]
#						}
#						"timerange" {
#							if [info exists order_conf(${section}.timerange_start)] {
#								set option_sec_value $order_conf(${section}.timerange_start)
#								if [catch {clock scan $option_sec_value} error ] {
#									fas_display_error "order::2edit_form - unable to convert timerange_start in section $section" fas_env
#								}
#							} else {
#								set option_sec_value $default_var(timerange_start)
#							}
#							set option_sec_name "Heure de d�but d'affichage"
#							set option_sec_description $op_description(timerange_start)
#							atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM]
#
#							if [info exists order_conf(${section}.timerange_stop)] {
#								set option_sec_value $order_conf(${section}.timerange_stop)
#								if [catch {clock scan $option_sec_value} error ] {
#									fas_display_error "order::2edit_form - unable to convert timerange_stop in section $section" fas_env
#								}
#							} else {
#								set option_sec_value $default_var(timerange_stop)
#							}
#							set option_sec_name "Heure de fin d'affichage"
#							set option_sec_description $op_description(timerange_stop)
#							atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC OPTION_PRIM_ENTRY]
#						}
#					}
#					atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM_ENTRY SECTION_ENTRY]
#
#					# jump_line_delay etc... options
#					if [info exists order_conf(${section}.start_delay)] {
#						set option_value $order_conf(${section}.start_delay)
#					} else {
#						set option_value $default_var(start_delay)
#					}
#					set option_name "D�lai avant le d�but du d�roulement (en ms)"
#					set option_description $op_description(start_delay)
#					atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM SECTION_ENTRY]
#
#					if [info exists order_conf(${section}.end_delay)] {
#						set option_value $order_conf(${section}.end_delay)
#					} else {
#						set option_value $default_var(end_delay)
#					}
#					set option_name "D�lai apr�s la fin du d�roulement (en ms)"
#					set option_description $op_description(end_delay)
#					atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM SECTION_ENTRY]
#
#					if [info exists order_conf(${section}.line_jump_delay)] {
#						set option_value $order_conf(${section}.line_jump_delay)
#					} else {
#						set option_value $default_var(line_jump_delay)
#					}
#					set option_name "D�lai entre chaque saut de lignes (en ms)"
#					set option_description $op_description(line_jump_delay)
#					atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM SECTION_ENTRY]
#
#					atemt::atemt_set FORM -bl [atemt::atemt_subst -insert -block SECTION_ENTRY FORM]
#				}
#			}
#			fas_fastdebug {order::2edit_form - terminated order file analyzis}
#			# end modif Xav
#		} else {
#			fas_fastdebug {order::2edit_form - processing section \'$section\' with edit_section=$edit_section}
#
#			# edit only a section
#			# Loading the template
#			set template_name [fas_name_and_dir::get_template_name fas_env edit_form.section.order.template]
#			fas_depend::set_dependency $template_name file
#			atemt::read_file_template_or_cache "EDIT_TEMPLATE" "$template_name"
#			# Then I print a template
#
#			atemt::atemt_set TITLE "[translate "Editing page "] $filename"
#
#			if { ![catch {fas_session::setsession ${basename}_section_order_conf } array_section_order_conf]} {
#			    array set order_conf $array_section_order_conf
#			}
#
#			# begin modif Xav
#			get_section fas_env $section order_conf
#			fas_debug "order::2edit_form - conf(order) is $order_conf(order)"
#			# end modif Xav
#			GetItemFromSection order_conf $section conf
#			set section_name $section
#
#			if [info exists conf(comment)] {
#				set option_value $conf(comment)
#			} else {
#				set option_value $default_var(comment)
#			}
#			set option_name "Commentaires"
#			set option_description $op_description(comment)
#			set option_form_name "option_comment"
#
#			atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -no OPTION_SEC_ENTRY OPTION_PRIM_TEXTAREA]
#			atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM_ENTRY SECTION]
#
#			if { ![info exists conf(type)]} {
#				fas_display_error "order::2edit_form - No type option in section $section"
#			} else {
#				set section_type $conf(type)
#			}
#
#			# first the Type option and his options
#			set option_name "Type"
#			set option_description $op_description(type)
#			set option_value $section_type
#			set option_type_page_selected ""
#			#set option_type_multi_selected ""
#			set option_type_file_selected ""
#			#set option_type_list_selected ""
#
#			switch $section_type {
#				"page" {
#					set option_type_page_selected "SELECTED"
#					option_sec_atemt_set conf page OPTION_PRIM_TYPE
#				}
#				"file" {
#					set option_type_file_selected "SELECTED"
#					option_sec_atemt_set conf file OPTION_PRIM_TYPE
#				}
#				# begin modif Xav
#				# "list" {
#				#	set option_type_list_selected "SELECTED"
#				#	option_sec_atemt_set conf order OPTION_PRIM_TYPE
#				#}
#				# "multi" {
#				#	set option_type_multi_selected "SELECTED"
#				#	option_sec_atemt_set conf multi_file OPTION_PRIM_TYPE
#				#	option_sec_atemt_set conf multirange_start OPTION_PRIM_ENTRY
#				#	option_sec_atemt_set conf multirange_stop OPTION_PRIM_ENTRY
#				#}
#				# end modif Xav
#			}
#			atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM_ENTRY SECTION_ENTRY]
#
#			if [info exists conf(condition)] {
#				set option_value $conf(condition)
#			} else {
#				set option_value $default_var(condition)
#			}
#			set option_name "Condition"
#			set option_description $op_description(condition)
#
#			set option_cond_none_selected ""
#			set option_cond_true_selected ""
#			set option_cond_false_selected ""
#			set option_cond_time_selected ""
#			set option_cond_timerange_selected ""
#			set option_cond_hour_selected ""
#
#			switch $option_value {
#				"none" {
#					set option_cond_none_selected "SELECTED"
#					atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -no OPTION_SEC OPTION_PRIM_COND]
#				}
#				"true" {
#					set option_cond_true_selected "SELECTED"
#					atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -no OPTION_SEC OPTION_PRIM_COND]
#				}
#				"false" {
#					set option_cond_false_selected "SELECTED"
#					atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -no OPTION_SEC OPTION_PRIM_COND]
#				}
#				"hour" {
#					set option_cond_hour_selected "SELECTED"
#					atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -no OPTION_SEC OPTION_PRIM_COND]
#				}
#				"time" {
#					set option_cond_time_selected "SELECTED"
#					if [info exists conf(time)] {
#						if [catch {clock scan $conf(time)} error ] {
#							fas_display_error "order::2edit_form - unable to convert time in section $section" fas_env
#						}
#					}
#					option_sec_atemt_set conf time OPTION_PRIM_COND
#				}
#				"timerange" {
#					set option_cond_timerange_selected "SELECTED"
#					if [info exists conf(timerange_start)] {
#						if [catch {clock scan $conf(timerange_start)} error ] {
#							fas_display_error "order::2edit_form - unable to convert timerange_start in section $section" fas_env
#						}
#					}
#					option_sec_atemt_set conf timerange_start OPTION_PRIM_COND
#					if [info exists conf(timerange_stop)] {
#						if [catch {clock scan $conf(timerange_stop)} error ] {
#							fas_display_error "order::2edit_form - unable to convert timerange_stop in section $section" fas_env
#						}
#					}
#					option_sec_atemt_set conf timerange_stop OPTION_PRIM_ENTRY
#				}
#
#			}
#			atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM_ENTRY SECTION_ENTRY]
#
#
#			if [info exists conf(start_delay)] {
#				set option_value $conf(start_delay)
#			} else {
#				set option_value $default_var(start_delay)
#			}
#			set option_name "D�lai avant le d�but du d�roulement (en ms)"
#			set option_form_name "option_start_delay"
#			set option_description $op_description(start_delay)
#			atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM SECTION_ENTRY]
#
#			if [info exists conf(end_delay)] {
#				set option_value $conf(end_delay)
#			} else {
#				set option_value $default_var(end_delay)
#			}
#			set option_name "D�lai apr�s la fin du d�roulement (en ms)"
#			set option_description $op_description(end_delay)
#			set option_form_name "option_end_delay"
#			atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM SECTION_ENTRY]
#
#			if [info exists conf(line_jump_delay)] {
#				set option_value $conf(line_jump_delay)
#			} else {
#				set option_value $default_var(line_jump_delay)
#			}
#			set option_name "D�lai entre chaque saut de lignes (en ms)"
#			set option_description $op_description(line_jump_delay)
#			set option_form_name "option_line_jump_delay"
#			atemt::atemt_set SECTION_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_PRIM SECTION_ENTRY]
#
#			atemt::atemt_set FORM -bl [atemt::atemt_subst -insert -block SECTION_ENTRY FORM]
#		}
#
#		# modif Xav set atemt::_atemt(EDIT_TEMPLATE) [atemt::atemt_subst -block FORM -block TITLE EDIT_TEMPLATE]
#		fas_fastdebug {order::2edit_form - prepared to substitute information}
#		atemt::atemt_set EDIT_TEMPLATE -bl [atemt::atemt_subst -block FORM -block TITLE EDIT_TEMPLATE]
#
#		# Here there is filename and dir to substitute
#		fas_fastdebug {order::2edit_form - substitution done, finalizing.}
#		return [atemt::atemt_subst -end EDIT_TEMPLATE]
#	}
#
	proc option_sec_atemt_set { order_config option prim_bloc} {
		upvar $order_config order_conf
		variable op_bloc
		variable op_description
		variable op_name
		variable default_var



		set option_sec_name $op_name($option)
		set option_sec_description $op_description($option)
		set option_sec_form_name "option_$option"
		if [info exists order_conf($option)] {
			set option_sec_value $order_conf($option)
		} else {
			set option_sec_value $default_var($option)
		}
		atemt::atemt_set OPTION_SEC_ENTRY -bl [atemt::atemt_set $op_bloc($option)]
		atemt::atemt_set OPTION_PRIM_ENTRY -bl [atemt::atemt_subst -insert -block OPTION_SEC_ENTRY $prim_bloc]
							

	} 



	proc 2edit { current_env filename } {
		fas_debug "order::2edit - entering"
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		fas_depend::set_dependency 1 always

		set all_order_file_lol [get_order_file_list $filename ]
		# Now I must get an ordered list of files in the order_file
		# Then I must get the list of files out of the order_file
		set in_lol [lindex $all_order_file_lol 0]
		set out_lol [lindex $all_order_file_lol 1]
		set message [order_store $filename $in_lol]
		# And I switch to the display of the directory edit_form
		# And now displaying the result
		set dir [rm_root [file dirname $filename]]
		# No reason to do substitution here
		# I try to display display the result directly in 
		# the message place of the directory display.
		fas_cgi_set message "$message"
		fas_cgi_set action edit_form
		set dir [file dirname $filename]
		global conf
		display_file dir $dir fas_env conf
		fas_exit
	}

	proc order_store { filename in_lol } {
		fas_fastdebug {neworder::order_store - Entering}
		set real_in_lol [lrange $in_lol 1 end]
		if { [catch {open $filename w} fid] } {
			set message "[translate "Problem while writing file :"] [rm_root $filename]"
		} else {
			set counter 0
			foreach file_list $real_in_lol {
				puts $fid "\[$counter\]"
				puts $fid "file = [lindex $file_list 2]"
				set start_delay [lindex $file_list 3]
				set end_delay [lindex $file_list 4]
				set line_jump_delay [lindex $file_list 5]
				if { $start_delay != "" } {
					puts $fid "start_delay = $start_delay"
				}
				if { $end_delay != "" } {
					puts $fid "end_delay = $end_delay"
				}
				if { $line_jump_delay != "" } {
					puts $fid "line_jump_delay = $line_jump_delay"
				}
				incr counter
			}
			close $fid
			set message "[translate "Successful writing of"] [rm_root $filename]"
		}
		return $message
	}
		

	# Replace all special html caracters by something cleaner
	# Certainly, I need to do some utf8 trick more
	proc html2iso { content } {
		regsub -all {&eacute;} $content {�} content
		regsub -all {&egrave;} $content {�} content
		regsub -all {&agrave;} $content {�} content
		regsub -all {&ecirc;} $content {�} content
		regsub -all {&acirc;} $content {�} content
		regsub -all {&ccedil;} $content {�} content
		regsub -all {&ugrave;} $content {�} content
		regsub -all {&ucirc;} $content {�} content
		regsub -all {&ouml;} $content {�} content
		return $content
	}

	proc iso2utf { content } {
		foreach re [list � � � � � � � � �] su [list e e e a a u i u o] {
			regsub -all $re $content $su content
		}
		return $content
		#return [encoding convertfrom iso8859-15 $content]
	}
		
	# Taking the mpeg21 template and filling it with the different values
	proc 2mpeg21 { current_env filename args } {
		upvar $current_env fas_env

		fas_debug "order::2mpeg21 - Entering"
		# Getting the content of the order file
		set content [fas_cache::get_file_or_cache fas_env order $filename]

		# Loading the template
		set template_name [fas_name_and_dir::get_template_name fas_env mpeg21.template]
		atemt::read_file_template_or_cache MPEG21_TEMPLATE $template_name
		fas_depend::set_dependency $filename always

		# Now I can do a substitution at the top level for these values
		ReadConfString $content order_var

		# I am going to parse the file and
		# create a corresponding xml
		# file with a section for each file
		global FAS_VIEW_URL
                global conf
                
                # Default values for mpeg21 properties                                
                set default(geographical_location_urn) "2.1.0.4"
                set default(geographical_location) "Metz"
                set default(genre_urn) "1.0"
                set default(genre) "Divers"
                set default(keyword) ""
                set default(resource_published_duration) "unknown"

                set compteur 0
		set date "[clock format [file mtime $filename] -format "%Y-%m-%d-%H-%M-%S"]"
		#set date "[clock format  [file mtime [add_root $page]] -format "%Y-%m-%d-%H-%M-%S"]"
		foreach section [OrderedGetSectionList order_var] {
			# Different cases to take into account
			# I just take into account page and file
			fas_fastdebug {order::mpeg21 - section => $section}
			# begin modif Xav
			get_section fas_env $section order_var
			# end modif Xav
			GetItemFromSection order_var $section res
			fas_fastdebug {order::mpeg21 - page}
			if { [info exists res(page)] } {
				# I found a file
				# I can add a new section to the mpeg21 file
				set page $res(page)
			} else {
				set page $res(file)
			}
			set full_page_path [add_root $page]
                        
                        # Getting the properties of this file
                        array unset current_resource_env
                        read_full_env $full_page_path current_resource_env
                        
                        # Now getting the filetype
                        set resource_filetype [guess_filetype $full_page_path conf current_resource_env]
                        
                        # If it is an order file, then I need to start again the process
                        # Else it is ok, I get the informations
                        set resource_mimetype $resource_filetype
                        if { [catch {::${resource_filetype}::mimetype} resource_mimetype] } {
                                set resource_mimetype "Application/Binary"
                                #set resource_mimetype "$resource_mimetype"                                                
                        }
                        set mimetype $resource_mimetype
                        
			# I need the following informations
                        # Pour chaque resource :                                                
                        # title, keyword, geographical_location_urn, geographical_location
                        # genre_urn, genre, resource_url, resource_published_start_time, mimetype
			set resource_url "${FAS_VIEW_URL}?file=$page"
			set resource_published_start_time "unknown"	
			if { [file readable $full_page_path] } {
				#set resource_published_start_time \
					"[clock format  [file mtime [add_root $page]] -format "%Y-%m-%dT%H:%M:%S"]"
				set resource_published_start_time "2006-12-31T16:25:00.0z"
			}
                                                                        
                        foreach key [list geographical_location_urn geographical_location genre_urn genre keyword resource_published_duration] {
                                if [info exists current_resource_env(mpeg21.${key})] {
					set content $current_resource_env(mpeg21.${key})
                                        #set $key $current_resource_env(mpeg21.${key})
                                        set $key [iso2utf [html2iso $content]]
                                } else {
                                        set $key $default($key)
                                }
                        }
                        set language "[::international::language]"
                        set title [iso2utf [html2iso [::${resource_filetype}::get_title $full_page_path]]]
			fas_fastdebug {neworder::2mpeg21 - full_page_path : $full_page_path title brut => [::${resource_filetype}::get_title $full_page_path] - title final : $title}

			# Now I must do the substitution
                        #fas_debug_parray ::atemt::_atemt "order::2mpeg21 avant atemt_subst_insert"
			atemt::atemt_set CONTAINER -bl [atemt::atemt_subst_insert RESOURCE  CONTAINER]
                        incr compteur
		}
		# Now filling the <container> section
		# For the main order
                # order_title, language, resource_url, published_start_time
                # releasedate_yyyy_mm_dd, url

                # First I create a published_start_time with the date of the resource
                set published_start_time \
                        "[clock format  [file mtime $filename] -format "%Y-%m-%dT%H:%M:%S"]+00:00"
		#set date "[clock format [file mtime $filename] -format "%Y-%m-%d"]"

                
		# I am going to consider that I put that in remarks
		# at start of the file
		set key_list [list order_title genre geographical_location \
		keyword caption_language releasedate_yyyy_mm_dd]
		get_mpeg21_values $content res $key_list

		# Setting the key values
		foreach key $key_list {
			set $key $res($key)
		}

		# Need to define url
		set url "${FAS_VIEW_URL}?file=[rm_root $filename]"

		atemt::atemt_set MPEG21_TEMPLATE -bl [atemt::atemt_subst -block CONTAINER MPEG21_TEMPLATE]
		return [atemt::atemt_subst -end MPEG21_TEMPLATE]
	}


	proc get_mpeg21_values { content current_res key_list} {
		upvar $current_res res
		foreach key $key_list {
			set res($key) ""
		}
		foreach line [split $content "\n"] {
			if { [regexp {^[#;]([^:]+):(.*)$} $line match key value] } {
				if { [lsearch -exact $key_list $key] > -1 } {
					fas_fastdebug {order::get_mpeg21_values : found $key => $value}
					set res($key) $value
				}
			}
		}
	}


	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 1
	}


	proc new { current_env conf dirname filename filetype ON_EXTENSION_FLAG } {
		upvar $current_env fas_env
		fas_debug "order::new - $dirname $filename"
 		set new::done 1
		set full_filename "[file join $dirname $filename]"

 		# Trying to open it for writing
 		if [ catch {set fid [open $full_filename w]}] {
 			# There was an error, I display it
 			fas_display_error "[translate "Impossible to open "] [rm_root $full_filename] [translate " for writing"]" fas_env -f $dirname
 		} else { 
 			close $fid
			if { !${ON_EXTENSION_FLAG} } {
				# I force the filetype
				set new_env(file_type) order
				# I write the env file
				global shadow_dir
				write_env [file join $dirname $shadow_dir $filename] new_env
				set fas_env(file_type) order
			}
			# And now the real high tech
			# I am going to jump to the edition page
			# on this empty file. So I need to cleanup
			global _cgi_uservar
			unset _cgi_uservar
			set _cgi_uservar(action) edit_form

			display_file order $full_filename fas_env fas_conf
			# And I exit as something will be displayed
			fas_exit
 		}
	}


	proc content_display { current_env content } {
		_cgi_http_head_implicit
	}


	proc content { current_env filename } {
		# What to do ??
		upvar $current_env fas_env
		return ""
	
	}


	proc display { current_env filename } {
		upvar $current_env fas_env
		fas_debug "order::display - $current_env $filename"

		set result "NO_DISPLAYED"
		set x 0
		while { $result != "DISPLAYED" && $x < 50 } {
			fas_debug "order::display $filename - trying $x time to display"
			set result [order::simple_display_order fas_env $filename]
			incr x
		}
		fas_debug "order::display $filename - tryed $x times to display"
		return $result
	}

	# Creating a clean name for using as a selector
	proc order_file_basename { filename } {
		set basename [rm_root $filename]
		regexp "^(.*?)\.order" $filename trash basename
		regsub -all {[^a-zA-Z01-9\-]} $basename {_} basename
		fas_fastdebug {order::order_file_basename - changing $filename into key $basename}
		return $basename
	}
		

	# The procedure to display the order file. 2 cases :
	#  * it is the top order file => display in turn
	#  * it is not the top order file, when arriving at the end => 
	#    * reset the related session variable (-1)
	#    * return an error
	# To know what is the top order file, I create a variable
	# with the name of the top order file
	# + a variable saying I am or not in a top order file
	proc simple_display_order { current_env filename } {
		upvar $current_env fas_env
		# So I try the simplest algorithm !!!
		# First determining where I must look at
		set basename [order_file_basename $filename]
		if [catch {fas_session::setsession order_${basename}_index} order_index] {
			set order_index -1
		}
		fas_fastdebug {simple_display_order : current order_index is $order_index}

		# OK now I must increment it
		incr order_index

		# Now I load the order file
		if [catch { ReadConf "$filename" order_conf} ] {
			fas_fastdebug {<div class="error">simple_display_order : $filename is not readable !!!</div>}
			return "NO_DISPLAYED"
		}

		# OK it was loaded, I continue
		set nb_section [GetNumberOfSection order_conf]
		if { ($order_index <  0) } {
			set order_index 0
		}
		variable top_order_flag
		if { $order_index >= $nb_section } {
			# 2 cases, either I am at the top, then I loop,
			# or I am in a sub section, then I must make an error
			# and increment the file in the order file from which
			# I come. If I make no error, I must stay on the same
			# order file => then I must decrement the counter above.
			if $top_order_flag {
				# I am at top, just increment and go back to 0
				set order_index 0
			} else {
				# I am not at top then
				# I must set the current session variable to come back at -1
				# and I must create an error
				fas_debug "simple_display_order - not at top order, then current order_${basename} set to -1"
				fas_debug "order::simple_display_order - and generate an error to go back at the top"
				set order_index -1
				fas_session::setsession order_${basename}_index $order_index
				error "order::simple_display_order => going up and taking the next file"
			}
		}
		fas_fastdebug {order::simple_display_order - $order_index => [GetNameSectionNumber order_conf $order_index]}
		main_log "Displaying section [GetNameSectionNumber order_conf $order_index] of $filename"

		GetItemFromSection order_conf  [GetNameSectionNumber order_conf $order_index ] res
		set last_result [simple_display_section fas_env res $filename]
		fas_session::setsession order_${basename}_index $order_index
		fas_debug "order::simple_display_order - end => last_result is $last_result"
		fas_debug "order::simple_display_order - next session index : order_${basename}_index $order_index"
		return $last_result
	}

	proc simple_display_section { current_env current_res filename } {
		upvar $current_env fas_env
		upvar $current_res res

		# So now, am I able to display what is in the section or not ?
		fas_debug_parray res "order::simple_display_section - res - section which is shown"
		
		# What is the file to display ?
		if  {  ![info exists res(file)] } {
			fas_debug "order::simple_display_section - no file in current section"
			return "NO_DISPLAYED"
		}
			
		# I now consider that the file, is in the file key of res
		set current_file_to_display [add_root $res(file)]

		return [simple_display_real_file fas_env res $current_file_to_display]
	}

	####### The goal here is just to find a way to handle
	####### different resolution (800x600, 1024x768, 1280x1024)
	####### and eventually a demonstration mode with added functions
	proc choose_final_target { current_cgi } {
		upvar $current_cgi my_cgi

		set final_target "rrooll"
		if { [info exists my_cgi(target)] } {
			set current_target $my_cgi(target)
			switch -exact -- $current_target {
				rrooll1 -
				rool1 {
					set final_target rrooll1
				}
				rrooll2 -
				rool2 {
					set final_target rrooll2
				}
				rrooll3 -
				rool3 {
					set final_target rrooll3
				}
			}
		}
		set my_cgi(target) $final_target
	}

	# So here it is the file that I will finally display
	# I create the _cgi_uservar, and then, I display
	proc simple_display_real_file { current_env current_res filename } {
		upvar $current_env fas_env
		upvar $current_res res
	
		variable default_var
		global FAS_PROG_ROOT
		global FAS_VIEW_URL
		global conf
		
		fas_fastdebug {order::simple_display_real_file $filename}
		
		foreach var [list START_DELAY END_DELAY LINE_JUMP_DELAY] {
			if { [info exists res([string tolower $var])] } {
				set $var $res([string tolower $var])
			} else {
				set $var $default_var([string tolower $var])
			}
			fas_fastdebug {order::simple_display_real_file - $var [set $var]}
		}
		
		read_full_env $filename current_file_env
		set filetype [guess_filetype $filename conf current_file_env ]

		# exists only for internet, do not see the use or the exception
		#set exists [${filetype}::exists current_file_env $filename]
		#if { $exists == 0 } {
		#	return "NO_DISPLAYED"
		#}
		fas_debug "order::simple_display_final_file - calling display_file $filetype $filename"

		global _cgi_uservar
		# I save the different delay :
		set _cgi_uservar(start_delay) $START_DELAY
		set _cgi_uservar(end_delay) $END_DELAY
		set _cgi_uservar(line_jump_delay) $LINE_JUMP_DELAY

		# rrooll rrooll1 rrooll2 rrooll3 ??? which one
		####### The goal here is just to find a way to handle
		####### different resolution (800x600, 1024x768, 1280x1024)
		####### and eventually a demonstration mode with added functions
		choose_final_target _cgi_uservar
		set display_result "NO_DISPLAYED"
		if [file exists ${filename}] {
			# 2 cases : $filename is an order file or not
			# If not an order file, display it, if error go to the next file
			# If it is an order file, as long as I have no error, I loop on the same file
			# then I must decrement the current session variable !!
			# If there is an error, ok, I go to the next file
			# and then display ;)
			## isn't is marvelous ?
			global BUS_GESTION_ERROR
			set BUS_GESTION_ERROR 1
			variable top_order_flag
			if { $filetype != "order" } {
				if { ![catch {display_file ${filetype} ${filename} current_file_env conf} current_result] } {
					set display_result "DISPLAYED"
				} else {
					set display_result "NO_DISPLAYED"
				}
			} else {
				# I am no more at the top of an order file : I enter in one
				variable top_order_flag
				set local_order_flag $top_order_flag
				set top_order_flag 0
				# Ok now I call the display of the order
				if { ![catch {display_file ${filetype} ${filename} current_file_env conf} current_result] } {
					# so no error 
					set display_result "DISPLAYED"
					# I must decrement the current counter for the session
					set order_index [fas_session::setsession order_${basename}_index]
					incr order_index -1
					fas_session::setsession order_${basename}_index $order_index
				} else {
					set display_result "NO_DISPLAYED"
				}
				# I may or may not be at top. It is stored in local_order_flag.
				set top_order_flag $local_order_flag
			}
			set BUS_GESTION_ERROR 0
			fas_debug "order::display_final_order_file - file displayed"
		}
		return $display_result
	}
		



    #
    # Try to display a order file
    # Return 1 if no display
    # return 0 if display
    #

	proc display_order_file { current_env filename order_dir} {
		upvar $current_env env
		
		fas_fastdebug {order::display_order_file - current_env $filename}
		
		# first, the basename
		# removing .order of the file, and all odd caracters in the file name
		#regexp "(?:.*/)?(\[^/\]+)\.order" $filename trash basename
		set basename $filename
		regexp "^(.*?)\.order" $filename trash basename
		regsub -all {[^a-zA-Z01-9\-]} $basename {_} basename
		fas_fastdebug {order::display_order_file - basename is $basename}

 		# gestion error
 		if [catch {fas_session::setsession order_error } order_error] {
 			set order_error "none"
 		}
 		if { "$order_error" == "${basename}_order_file" } {
 			fas_session::setsession order_error "none"
 			return "NO_DISPLAYED"
 		}

		# AL 7/9/2006 -removiing order_current_action
 		#if [catch {fas_session::setsession order_current_action } last_order_current_action] {
		#	fas_session::setsession order_current_action none
 			#set last_order_current_action none
 		#}
# 		puts $last_order_current_action
 		#fas_session::setsession order_current_action "${basename}_order_file"

		# The current index in the current order file is in order_index
		if [catch {fas_session::setsession order_${basename}_index} order_index] {
			set order_index 0
			# AL 7/9/2006 removing next line
			# fas_session::setsession order_${basename}_index -1
		}
		fas_debug "order::display_order_file : order_index is $order_index"
		# AL removing the next idiot line - 7/9/20006
		#set real_filename [add_root2 $filename]
		set real_filename $filename

		# Try to open the file
		fas_fastdebug {order::display_order_file - reading $real_filename - as order file}
		if { [file readable "$real_filename"] } {
			if [catch { ReadConf "$real_filename" order_conf} ] {
				fas_display_error "order::display_order_file - Error while loading $real_filename" fas_env -f $filename
			}

			set nb_section [GetNumberOfSection order_conf]
			if { ($order_index < 0) || ($order_index >= $nb_section) } {
				set order_index 0
			}

			set last_result "NO_DISPLAYED"
			set try_counter 0
			while { (${try_counter} < $nb_section) && ($last_result == "NO_DISPLAYED")} {
				fas_debug "order::display_order_file : asking for display_section $order_index and it is the $try_counter time"
				set last_result [display_section env order_conf ${basename} [GetNameSectionNumber order_conf $order_index ] $filename $order_dir]
				if { $last_result == "DISPLAYED" } {
					break
				}
				incr order_index
				incr try_counter
				if {${order_index} >= $nb_section} {
					set order_index 0
				}

			}
			fas_session::setsession order_${basename}_index $order_index
			fas_debug "order::display_order_file - end => last_result is $last_result"
			return $last_result

		} else {
			fas_display_error "order::display_order_file - File $real_filename not exists" fas_env -f $filename
		} 

	}

    #
    # Display the next page of section if condition is true
    # Return 1 if no display
    # return 0 if display
    #
	proc display_section { current_env config basename section filename order_dir} {
		upvar $config order_conf
		upvar $current_env env
		variable default_var
		
		global ::_cgi_uservar

		fas_debug "order::display_section - $current_env $config $basename $section $filename"

 		# gestion error
 		if [catch {fas_session::setsession order_error } order_error] {
 			set order_error "none"
 		}
 		if { $order_error == "${basename}_section" } {
 			fas_session::setsession order_error "none"
# 			fas_session::setsession order_sub_${basename}_index -1
 			return "NO_DISPLAYED"
 		}

		if [catch {fas_session::setsession order_sub_${basename}_index} subpage_index] {
			set subpage_index -1
			fas_session::setsession order_sub_${basename}_index -1
		}
	
		fas_fastdebug {order::display_section - checking verif_condition}
		if { [verif_condition order_conf $section] == "TRUE" } {
			# begin modif Xav
			get_section env $section order_conf
			# end modif Xav
			GetItemFromSection order_conf $section res
			# I now consider that the file, is in the file key of res
			# Then, I create a type from the filetype of the file
			# If the file is order => type file
			# If the file is anything else => type page
			if { [info exists res(file)] } {
				set res(page) $res(file)
				if { [regexp {\.order$} $res(file)] } {
					set res(type) file
				} else {
					set res(type) page
				}
			} else {
				return "NO_DISPLAYED"
			}
			fas_fastdebug {order::display_section - verif_condition is true}
			fas_fastdebug {order::display_section - res(type) is $res(type)}
			switch $res(type) {
				"page" {
					# page, file not important, one is order
					# the other not.
					if { ![info exists res(page)] } {
						set res(page) $res(file)
					}
					if { $subpage_index <= 0 } {
						set file $res(page)
						set subpage_index 1
						fas_session::setsession order_sub_${basename}_index $subpage_index
						if { [display_final_order_file env $file $basename $order_dir res] == "DISPLAYED"} {
	# AL 7/9/2006 -removiingurrent_action
							#fas_session::setsession order_current_action $last_order_current_action
							fas_debug "order::display_section - section displayed"
							return "DISPLAYED"
						}
					}
					# no file diplayed then return 1
					if { $subpage_index >= 1} {
						set subpage_index -1
						fas_session::setsession order_sub_${basename}_index $subpage_index
					}
					fas_debug "order::display_section - section not displayed"
					return "NO_DISPLAYED"
				}
				"file" {
					fas_debug "order::display_section - displaying a section of type file"
					if {[info exists res(file)]} {
						# display_file
						set file $res(file)
						set displayed [display_order_file env [add_root "$file"] $order_dir] 
						fas_debug "order::display_section - end file $file"
						return $displayed
					} else {
						fas_display_error "order::display_section - Section $section of file [rm_root $filename] is of type file, there should be a key file (file = ) in this section." env
						fas_debug "order::display_section - type file - missing a key file = in order file [rm_root $filename]"
						return "NO_DISPLAYED"
					}
				}
			}
		}
		fas_debug "order::display_section - section not displayed"
		return "NO_DISPLAYED"
	}

	proc display_final_order_file { current_env filename basename order_dir section_config} {
		upvar $current_env env
		upvar $section_config section_conf
		global conf
		variable default_var
		
		global FAS_PROG_ROOT
		global FAS_VIEW_URL
		
		fas_debug "order::display_final_order_file $filename"
		
		global BUS_GESTION_ERROR 
		set BUS_GESTION_ERROR 1
		set basename $filename
		regexp "^(.*?)\.order" $filename trash basename
		regsub -all {[^a-zA-Z01-9\-]} $basename {_} basename
		fas_fastdebug {order::display_final_order_file - basename is $basename}
		#regexp "(?:.*/)?(\[^/\]+)\.order" $filename trash basename

 		# gestion error
 		if [catch {fas_session::setsession order_error } order_error] {
 			set order_error "none"
 		}
 		if { "$order_error" == "${basename}_final_order_file" } {
 			fas_session::setsession order_error "none"
 			return "NO_DISPLAYED"
 		}

		
		# AL 7/9/2006 -removiing order_current_action
 		#if [catch {fas_session::setsession order_current_action } last_order_current_action] {
 		#	set last_order_current_action none
 		#}
 		#fas_session::setsession order_current_action "${basename}_final_order_file"

		#fas_debug "order::display_final_order_file $filename - last_order_current_action is $last_order_current_action"

		#set file_url [rm_root $filename]
		#set file_url $filename
		#set order_dir_tmp [rm_root $order_dir]
		#set conf(order_rrooll_url) "${FAS_VIEW_URL}?file="
		#set RROOLL_URL "$conf(order_rrooll_url)${order_dir_tmp}"

		foreach var [list START_DELAY END_DELAY LINE_JUMP_DELAY] {
			if { [info exists section_conf([string tolower $var])] } {
				set $var $section_conf([string tolower $var])
			} else {
				set $var $default_var([string tolower $var])
			}
			fas_debug "order::display_final_order_file $filename - $var [set $var]"
		}
		
		read_full_env [add_root2 $filename] current_file_env

		set filetype [guess_filetype $filename conf current_file_env ]
		set real_filename [add_root2 $filename]

		if [catch {set exists [${filetype}::exists current_file_env $real_filename]}] {
			# error, considere that file exists
			set exists 1
		}
		if { $exists == 0 } {
			return "NO_DISPLAYED"
		} else {
			fas_debug "order::display_final_order_file - calling display_file $filetype $filename"

			global _cgi_uservar
			# I save the different delay :
			set _cgi_uservar(start_delay) $START_DELAY
			set _cgi_uservar(end_delay) $END_DELAY
			set _cgi_uservar(line_jump_delay) $LINE_JUMP_DELAY

			set final_target rrooll
			####### The goal here is just to find a way to handle
			####### different resolution (800x600, 1024x768, 1280x1024)
			####### and eventually a demonstration mode with added functions
			if { [info exists _cgi_uservar(target)] } {
				set current_target $_cgi_uservar(target)
				switch -exact -- $current_target {
					rrooll1 -
					rool1 {
						set final_target rrooll1
					}
					rrooll2 -
					rool2 {
						set final_target rrooll2
					}
					rrooll3 -
					rool3 {
						set final_target rrooll3
					}
				}
			}
			set _cgi_uservar(target) $final_target
			## IMPORTANT !
			## test to avoid the error if the file doeexist
			set display_result "NO_DISPLAYED"
			if [file exists ${real_filename}] {
				# and then display ;)
				## isn't is marvelous ?
				#display_file ${filetype} ${real_filename} current_file_env conf
				
				## I think that the catching is finally to dangerous
				if { ![catch {display_file ${filetype} ${real_filename} current_file_env conf} ] } {
					set display_result "DISPLAYED"
					# There was an error, I suppose that nothing was displayed
				#	catch { unset _cgi_uservar(target) }

				#	fas_session::setsession order_current_action $last_order_current_action
				#	fas_debug "order::display_final_order_file - file NOT DISPLAYED - file does not exist"
				#	set BUS_GESTION_ERROR 0
				#	return "NO_DISPLAYED"
				}

				#set BUS_GESTION_ERROR 0
			} else {
				## display a default file
				#display_file txt [add_root "/any/rool/not_found.txt"] current_file_env conf
				#unset _cgi_uservar(target)

		# AL 7/9/2006 -removiing order_current_action
				# fas_session::setsession order_current_action $last_order_current_action
				#fas_debug "order::display_final_order_file - file NOT DISPLAYED - file does not exist"
				#set BUS_GESTION_ERROR 0
				#return "NO_DISPLAYED"
			}
			#unset _cgi_uservar(target)

		# AL 7/9/2006 -removiing order_current_action
			#fas_session::setsession order_current_action $last_order_current_action
			set BUS_GESTION_ERROR 0
			fas_debug "order::display_final_order_file - file displayed"
			return $display_result
		}
	}

    #
    # Verify the condition of section in conf
    #
	proc verif_condition { conf section } {
		upvar $conf con
		fas_debug "order::verif_condition - $conf $section"

		# begin modif Xav
		get_section "" $section con
		# end modif Xav
		GetItemFromSection con $section res
		if { [info exists res(condition)] } {
			switch -exact -- $res(condition) {
				"none" {
					return "TRUE"
				}
				
				"true" {
					return "TRUE"
				}

				"false" {
					return "FALSE"
				}

				"time" {
					if [info exists res(time)] {
						if [catch {set time [clock scan $res(time)]}] {
							fas_display_error "order::verif_condition - unable to convert time in section $section" fas_env 
						}
						set localtime [clock scan [clock format [clock seconds] -format "%H:%M"]]
						if { $localtime == $time} {
							return "TRUE"
						} else {
							return "FALSE"
						}
					} else {
						fas_display_error "order::verif_condition - No time option in section $section" fas_env 
					}
				}

				"timerange" {
					if {[info exists res(timerange_start)] && [info exists res(timerange_stop)]} {
						if [catch {set start [clock scan $res(timerange_start)]}] {
							fas_display_error "order::verif_condition - Unable to convert timerange_start in section $section" fas_env 
						}
						if [catch {set stop [clock scan $res(timerange_stop)]}] {
							fas_display_error "order::verif_condition - Unable to convert timerange_stop in section $section" fas_env 
						}
						set localtime [clock seconds] 
						if { $start <= $localtime && $localtime <= $stop } {
							return "TRUE"
						} else {
							return "FALSE"
						}
					} else {
						fas_display_error "order::verif_condition - No timerange_start or timerange_stop option in section $section" fas_env 
					}
				}

				"hour" {
					set local_minute [clock format [clock seconds] -format %M]
					if { $local_minute == "00" } { 
						return "TRUE"
					} else {
						return "FALSE"
					}

				}

				default {
					fas_display_error "order::verif_condition - Unknow condition in section $section" fas_env
				}

			} 
			# end switch
		} else {
			return "TRUE"
		}
	}
    # end verif_conditon

	proc copy_archive { current_env filename dest_dirname } {
		upvar $current_env env
		
		fas_debug "order::copy_archive - $current_env $filename $dest_dirname"

		# first copy the directory
		regexp "^(.*)/.+?$" $filename trash parent_dir
		set file [rm_root2 $filename]
		dir::copy_archive env $parent_dir $dest_dirname

		# second copy the file with his mana
		if [catch { file copy -force -- $filename "$dest_dirname$file" }] {
			log::log error "error while copy $file in [rm_root2 $dest_dirname$file]"
		}
		regsub "^(.*/)(.+?)$" $file "\\1.mana/\\2" mana_filename
		set orig_mana_filename [add_root2 $mana_filename]
		if [file exists $orig_mana_filename] {
			if [catch { file copy $orig_mana_filename "$dest_dirname$mana_filename" }] {
				log::log error "error while copy $mana_filename in [rm_root2 $dest_dirname$mana_filename]"
			} 
		}

		set real_filename [add_root2 $filename]
		# Try to open the file
		if { [file readable "$real_filename"]} {
			if { [info exists order_conf] } {unset order_conf}
			if [catch { ReadConf "$real_filename" order_conf} ] { 
				log::log error "Error while loading $real_filename"
			} else {
				set nb_section [GetNumberOfSection order_conf]
				set order_index 0
				while { (${order_index} < $nb_section) } {
					copy_archive_section env order_conf [GetNameSectionNumber order_conf $order_index ] $filename $dest_dirname
					incr order_index
				}
			}
		} else {
			log::log error "File $real_filename not exists"
		} 
		
	}

	#
	# Copy in archive all files in a section
	#
	proc copy_archive_section { current_env order_config section filename dest_dirname } {
		upvar $order_config order_conf
		upvar $current_env env
		variable default_var

		fas_debug "order::copy_archive_section - $current_env $order_config $section $filename $dest_dirname"

		# get section
		set subpage_index 0
		# begin modif Xav
		get_section env $section order_conf stype
		# end modif Xav
		GetItemFromSection order_conf $section res		
		if { [ info exists res(type) ] } {
			switch -exact -- $res(type) {
				# begin modif Xav
				"page" {
					if {[info exists res(page)]} {
						copy_archive_final_order_file env $res(page) res $dest_dirname
					} else {
						log::log warning "No page in section $section in [rm_root2 $filename]"
					}
				}
				"file" {
					if {[info exists res(file)]} {
						set file [concat $res(file)]
						copy_archive env [add_root2 "$file"] $dest_dirname
						fas_debug "order::copy_archive_section - end file $file"
					} else {
						log::log warning "No file in section $section in [rm_root2 $filename]"
					}
				}
				# "list" {
				#	if {[info exists res(order)]} {
				#		set list [concat $res(order)]
				#		set length_list [llength $list]
				#		while { $subpage_index < $length_list} {
				#			set file [lindex $list $subpage_index]
				#			set file [add_root2 $file]
				#			copy_archive_final_order_file env $file res $dest_dirname
				#			set subpage_index [expr $subpage_index + 1]
				#		}
				#	} else {
				#		log::log warning "No order in section $section in [rm_root2 $filename]"
				#	}
				#}
				# "multi" {
				#	if {[info exists res(multi_file)]} {
				#		set file $res(multi_file)
				#		copy_archive_final_order_file env $file res $dest_dirname
				#	} else {
				#		log::log warning "No multi_file option in section $section in [rm_root2 $filename]"
				#	}
				#}
				
				default {
					log::log warning "Type in section $section isn't valid in [rm_root2 $filename]"
				}
			}
		} else {
			log::log warning "No type in section $section in [rm_root2 $filename]"
		}
	}

	proc copy_archive_final_order_file { current_env filename section_config dest_dirname } {
		upvar $current_env env
		upvar $section_config section_conf
		global conf
		
		global FAS_PROG_ROOT
		global FAS_VIEW_URL

		fas_debug "order::copy_archive_final_order_file - $current_env $filename $section_config $dest_dirname"

		# read env and get filetype of final_order_file
		read_full_env [add_root2 $filename] current_file_env
		set filetype [guess_filetype $filename conf current_file_env]

		# if function ::${filetype}::copy_archive exists then use it
		# else use simple_copy_archive
		set filetype_copy_archive "::${filetype}::copy_archive"
		if { [llength [info commands $filetype_copy_archive]] > 0 } {
			$filetype_copy_archive env [add_root2 $filename] $dest_dirname
		} else {
			simple_copy_archive env [add_root2 $filename] $dest_dirname
		}
	}

	# 
	# copy filename, his parent directory and his man in dest_dirname  
	#
	proc simple_copy_archive { current_env filename dest_dirname } {
		upvar $current_env env
		
		fas_debug "order::simple_copy_archive - $current_env $filename $dest_dirname"

		# first copy the directory
		regexp "^(.*)/.+?$" $filename trash parent_dir
		set file [rm_root2 $filename]
		dir::copy_archive env $parent_dir $dest_dirname
		
		# second copy the file with his mana
		if { ![file exists "${dest_dirname}${file}"]} {
			if [file exists "$filename"] {
				if [catch {file copy -force -- $filename "${dest_dirname}${file}"}] {
					log::log error "error while copy $file"
				}
				regsub "^(.*/)(.+?)$" $file "\\1.mana/\\2" mana_filename
				if [file exists [add_root2 $mana_filename]] {
					if [catch { file copy [add_root2 $mana_filename] "$dest_dirname$mana_filename" }] {
						log::log error "Error while copy $mana_filename"
					} 
				}
			} else {
				log::log warning "File [rm_root2 $filename] don't exists"
			}
		}
	}
			

}
