lappend filetype_list order_dir

source "${FAS_PROG_ROOT}/readconf.tcl"

namespace eval order_dir {
	package require md4
    
    global DEBUG_PROCEDURES
    eval $DEBUG_PROCEDURES

    global STANDARD_PROCEDURES
    eval $STANDARD_PROCEDURES
    
    set DEBUG 1
    
    proc new_type { current_env filename } {
    		fas_debug "order_dir::new_type : entering"
		if { ![catch {set action [fas_get_value action] } ] } {
    			fas_debug "order_dir::new_type : action is $action"
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "order_dir:new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
    		fas_debug "order_dir::new_type : leaving on error for display"
		#error 1
		return ""
    }

    # 	# This procedure returns the list of important session variables for
    # 	# this type of file
    # 	proc important_session_keys { } {
    # 		# not any one
    # 		return [list "order_index"]
    # 	}

    proc env { args } {
	set env_list ""
	lappend env_list [list "order_dir.archivedir" "Directory where archive to be sent to a remote ucome are placed" admin]
	return $env_list
    }

    # 	# Now all procedures for the actions

    # I will always ask for a new object from a directory
    # So then, I need to pick up the adapted function
    # depending on the filetype for the new object
    # But basically, I create a new object and I
    # call an edit function on it. Well it depends  
    # on the filetype.
    proc 2new { current_env filename } {
		upvar $current_env fas_env
		fas_debug "order_dir::2new - Entering order_dir::2new current_env $filename"
		dir::2new env $filename
# 		# Now I need to know the projected filetype
# 		# And the name of the future file
# 		set new_filetype order
# 		# To get the name of the future file, I need to extract
# 		# the list of the current files
# 		# Then I call the edit function on it
# 		# First the list of files in the directory
# 		# Creating the file
# 		if { [catch { order::new  fas_env $filename $current_index  } error ] } {
# 			# There was an error, I suppose that 
# 			# the new method does not exist
# 			# I consider that there is no need to process
# 			# the new order
# 			set new::done 1
# 			fas_display_error "[translate "It was not possible to create a file of type"] $new_filetype - $error" fas_env -f $filename 
# 		} else { 
# 			set new::done 1
# 		}
    }
	proc get_archive_dir { current_env } {
		upvar $current_env fas_env
		if { [info exists fas_env(order_dir.archivedir) ] } {
			set archivedir [add_root $fas_env(order_dir.archivedir)]
		} elseif { [info exists fas_env(root_directory) ] } {
			set archivedir [file join [add_root $fas_env(root_directory)] archive]
		} else {
			set archivedir [file join [add_root "/"] archive]
		}
		return $archivedir
	}

    proc 2edit_form { current_env filename } {
		fas_debug "order_dir::2edit_form - current_env "
		upvar $current_env env
		global conf
		return [dir::2edit_form env $filename]

# 		# The directory is its own dependency
# 		fas_depend::set_dependency $filename file

# 		# Template name may come from the env, then I take it
# 		fas_depend::set_dependency $filename env

# 		# First I need some informations 
# #		set display [fas_get_value display -default "order_name,uri,start_time,end_time,rolling_speed,Delete,Edit"]
# 		set display [fas_get_value display -default "order_name,Copy,Edit,Properties,Delete"]
# 		set order [fas_get_value order -default "shortname"]
# 		set extension_list [fas_get_value extension_list -default "*.order"]
# 		set display_list [split $display ","]
# 		set file_lol [get_file_lol $filename env -w $display_list]

# 		set message [fas_get_value message -default ""]

# 		#set env(dir.template) order_dir.tmpl
# 		set content [dir::display_file_lol $file_lol env -title "[translate "Order management"]" -d $display_list -m $message -r [rm_root $filename]]
# 		return $content
    }

    proc 2edit { current_env filename } {
		upvar $current_env fas_env
		global _cgi_uservar
		# So I get a list with :
		# the previous associated index,
		# the new index
		# I need to move the files to take into account the new order
		# To be precise :
		#  * I must first create a list of the new order (it may
		# be different of what was entered,
		#  * then I copy the old files to the new list with a tmporder
		# extension
		#  * I delete the old files, and rename the new one	
		#    with the good extension.
		# BIIIIIRKKKKK	
		# I may try to avoid to move file that do not move

		# First importing all the values
		set counter 0
		set order_file_list ""
		while { [info exists _cgi_uservar(ori_$counter)] && [info exists _cgi_uservar(short_$counter)] } {
			lappend order_file_list [list $_cgi_uservar(ori_$counter) $_cgi_uservar(short_$counter)]
			incr counter
		}
		fas_debug "order_dir::2edit - order_file_list => $order_file_list"
		# So basically I order on the second index
		set ordered_file_list [lsort -integer -index 1 $order_file_list]

		# Now I copy the old files to the new one
		set counter 0
		set errors 0
		set errorstr ""
		foreach file_list $ordered_file_list {
			set ori_file "[file join $filename [format "%04d" [lindex $file_list 0]]].order"
			set target_file  "[file join $filename [format "%04d" $counter]].tmporder"
			if { [catch { file rename -force $ori_file $target_file }] } {
				append errorstr "<br>Problem rename $ori_file to $target_file"
				incr errors
			}
			incr counter
		}
		
		# Now I copy back to order
		while { $counter > 0 } {
			incr counter -1
			set ori_file "[file join $filename [format "%04d" $counter]].tmporder"
			set target_file "[file join $filename [format "%04d" $counter]].order"
			if { [catch { file rename -force $ori_file $target_file }] } {
				append errorstr "<br>Problem rename $ori_file to $target_file"
				incr errors
			}
		}

		# OK that was it, now I redisplay the whole thing in edit_form
		if { $errors == 0 } {
			set message "[translate "Successful reordering"]"
		} else {
			set message "[translate "Problem while reordering"]<br>$errorstr"
		}
		
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		
		global DEBUG
		if $DEBUG {
			set _cgi_uservar(debug) "$DEBUG"
		}
		set _cgi_uservar(action) "edit_form"
		global conf
		display_file order_dir $filename fas_env conf
		fas_exit
    }

#     # NAME : get_file_lol  -- for order_dir and order files
#     # Function : send back the list of files corresponding to filter (default *)
#     # The file is ALLWAYS sent back at the start of the list. You do
#     # not need to mention it.
#     # Arguments :
#     #	-what what_list : a list of elements to send back. Possible values 
#     #                         are file, shortname, extension, filetype, dir, title, size, mtime, 
#     # Plus the specific to order special following values :
#     # uri, start_time, rolling_speed, end_time, 
#     # that will be taken directly from the file 

#     # The display will always be in the order of the .order file (numerical).
#     # The result is a list of list (lol) the first element of which
#     # is the list of elements in each sublist.
#     proc get_file_lol { dir current_env args } {
# 		fas_debug "order_dir::get_file_lol - $dir - $args"
# 		global conf
# 		upvar $current_env fas_env
# 		set state menu_args
# 		set filter "*.order"
# 		set what_list "file"
# 		foreach arg $args {
# 			switch -exact -- $state {
# 				menu_args {
# 					switch -glob -- $arg {
# 						-w* {
# 							set state what
# 						}
# 						default {
# 							# nothing to do
# 						}
# 					}
# 				}
# 				what {
# 					set what_list $arg
# 					set state menu_args
# 				}
# 			}
# 		}
# 		# first getting the file list
# 		set filter_string "[file join $dir $filter]"
# 		#fas_debug "$filter_string"
# 		set file_list [glob -type {f} -nocomplain $filter_string]
		
# 		#fas_debug "set file_list \[glob -type f -nocomplain $filter_string\]"
# 		#fas_debug "set file_list [glob -type f -nocomplain $filter_string]"
# 		#fas_debug  "$file_list" 
# 		set final_file_list ""
# 		set what_list [linsert $what_list 0 "file"]
# 		foreach file $file_list {
# 			# I forget the following values
# 			catch { unset current_order }
# 			# I load the order file
# 			read_env $file current_order
# 			#fas_debug_parray current_order "order:get_file_lol - current_order"
# 			set current_file_list ""
# 			foreach element $what_list {
# 				switch -exact -- $element {
# 					file {
# 						# This file is only used after
# 						# for creating url => I suppress
# 						# the root from it
# 						lappend current_file_list [rm_root $file]
# 					}
# 					shortname {
# 						set extension [file extension $file]
# 						regsub "$extension\$" [file tail $file] {} shortname
# 						lappend current_file_list $shortname
# 					}
# 					extension {
# 						set extension [string trim [file extension $file]]
# 						if { $extension == "" } {
# 							set extension "&nbsp;"
# 						}
# 						lappend current_file_list $extension
# 					}
# 					filetype {
# 						set current_filetype [guess_filetype $file conf fas_env]
# 						lappend current_file_list $current_filetype
# 					}
# 					dir {
# 						set dir [file dirname $file]
# 						lappend current_file_list $dir
# 					}
# 					title { 
# 						# OK I must get the title of this file type
# 						set filetype [guess_filetype $file conf fas_env]
# 						#set title [get_title -type $extension $file]
# 						set title [${filetype}::get_title $file ]
# 						lappend current_file_list $title
# 					}
# 					size {
# 						lappend current_file_list [file size $file]
# 					}
# 					mtime {
# 						lappend current_file_list [file mtime $file]
# 					}
# 					order_name {
# 						# Only for order directories
# 						# to display 5 instead of 0005
# 						# directly inspired of shortname
						
# 						#set extension [file extension $file]
# 						#regsub "$extension\$" [file tail $file] {} shortname
# 						lappend current_file_list [order::extract_nber [order::extract_name $file]]
# 					}
# 					uri {
# 						if { [info exists current_order(url)] } {
# 							set current_url $current_order(url)
# 						} else {
# 							set current_url "file:$current_order(filename)"
# 						}
# 						lappend current_file_list $current_url
# 					}
# 					start_time {
# 						set start_time ""
# 						if { [info exists current_order(START_DELAY)] } {
# 							set start_time $current_order(START_DELAY)
# 						}
# 						fas_debug "order_dir::get_file_lol - start_time => $current_order(START_DELAY) - $start_time"
# 						lappend current_file_list $start_time
# 					}
# 					rolling_speed {
# 						set rolling_speed ""
# 						if { [info exists current_order(LINE_JUMP_DELAY)] } {
# 							set rolling_speed $current_order(LINE_JUMP_DELAY)
# 						}
# 						fas_debug "order_dir::get_file_lol - rolling_speed => $current_order(LINE_JUMP_DELAY) - $rolling_speed"
# 						lappend current_file_list $rolling_speed
# 					}
# 					end_time {
# 						set end_time ""
# 						if { [info exists current_order(END_DELAY)] } {
# 							set end_time $current_order(END_DELAY)
# 						}
# 						fas_debug "order_dir::get_file_lol - end_time => $current_order(END_DELAY) - $end_time"
# 						lappend current_file_list $end_time
# 					}
# 					Copy -
# 					Edit -
# 					Delete -
# 					Properties -
# 					default {
# 						# I put an empty value to keep
# 						# the number of elements in the list
# 						# equal to the input
# 						lappend current_file_list ""
# 					}
# 				}
# 			}
# 			#fas_debug "current_file_list : $current_file_list"
# 			lappend final_file_list $current_file_list
# 		}
# 		# I order depending of shortname
# 		set order_element [lsearch -exact $what_list "shortname"]
# 		if { $order_element >= 0 } {
# 			set file_list [lsort -index $order_element $final_file_list]
# 		} else {
# 			set file_list [lsort -index 0 $final_file_list]
# 		}
# 		set file_list [linsert $file_list 0 $what_list]
# 		fas_debug "order_dir::get_file_lol : result => $file_list"
# 		return $file_list
#     }




    proc 2fashtml { current_env args } {
		upvar $current_env env
		return "[eval dir::2fashtml env $args]"
    }


    proc display { current_env filename } {
		upvar $current_env env
		fas_debug "order_dir::display - $current_env $filename"
		fas_session::setsession order_current_action "none"		
		global BUS_GESTION_ERROR
		global FATAL_ERROR

		set loop 0
		set displayed "NO_DISPLAYED_"
		# first display a page of cond.order if it's possible
		if { [file exists [add_root2 "$filename/cond.order"] ] } {
			while [catch {order::display_order_file env [add_root2 "$filename/cond.order"] [add_root2 $filename] } displayed ] {
				if { $BUS_GESTION_ERROR == "1" } {
					incr loop
					if { $loop >= 100 } {
						set FATAL_ERROR 1
					}
					if { $loop >= 101 } {
						break
					}
				} else {
					set FATAL_ERROR 1
					fas_display_error "$displayed" fas_env -e
					break
				}
			}
		}
		set loop 0
		# display main.order
		while { $displayed != "DISPLAYED" } {
			if [catch { order::display_order_file env [add_root2 "$filename/main.order"] [add_root2 $filename] } displayed] {
				if { $BUS_GESTION_ERROR == "1" } {
					incr loop
					if { $loop >= 40} {
						set FATAL_ERROR 1
					}
					if { $loop >= 101 } {
						break
					}
				} else {
					set FATAL_ERROR 1
					fas_display_error "$displayed" fas_env -e
					break
				}
			}
		}
		fas_debug "order_dir::display - end"


    }
    # end display

    proc get_title { filename } {
		return "[translate "RrOoLling order of "] $filename"
    }


    proc 2archive_full { current_env filename } {
		upvar $current_env env
		global conf
		global _cgi_uservar
		global ROOT
		set ARCHIVE_DIR [get_archive_dir env]
		set TARGZ_ARCHIVE_DIR [file join $ARCHIVE_DIR targz]
		set FULL_ARCHIVE_DIR [file join $ARCHIVE_DIR full]
		set LAST_ARCHIVE_DIR [file join $ARCHIVE_DIR last]
		set SYNC_ARCHIVE_DIR [file join $ARCHIVE_DIR sync]
		fas_debug "order_dir::2archive_full - $current_env $filename"

		fas_depend::set_dependency $filename always

		set archive_type "all"
		if [info exists _cgi_uservar(archive_type)] {
			set archive_type $_cgi_uservar(archive_type)
		}
		switch $archive_type {
			"all" -
			"sync" -
			"full" {}
			default {
				set archive_type "all"
			}
		}


		# make 
		regsub -all -- "^/" [rm_root2 $filename] "" dest_targz
		regsub -all -- "/"  $dest_targz "_" dest_targz

		
		set localtime [clock format [clock seconds] -format "%y%m%d_%H%M%S"]
		set dest_full_targz "${TARGZ_ARCHIVE_DIR}/${dest_targz}_full_${localtime}.tar.gz"
		set dest_sync_targz "${TARGZ_ARCHIVE_DIR}/${dest_targz}_sync_${localtime}.tar.gz"

		# init log
		if [catch { file mkdir ${filename}/log }] {
			log::log error "Can not create $filename/log dir"
		}
		# rotate old log file
		# in reality, create a new log file and change symbolic link
		set today_log ${filename}/log/archive.[clock format [clock scan "today"] -format "%y%m%d"].log
		set fdlog [open $today_log a]
		if [ info exists fdlog ] {
			log::lvChannelForall $fdlog
			# make a link archive.log -> $today_log
			set log_archive_link "${filename}/log/archive.log"
			if [catch {file delete $log_archive_link}] {
				log::log error "Can not delete $log_archive_link"
			}
			if [catch {file link -symbolic "$log_archive_link" $today_log}] {
				log::log error "Can not create link $log_archive_link"
			}
		} else {
			log::lvChannelForall stderr
			log::log error "Could not open $today_log"
			log::log warning "All log messages in stderr"
		}
		log::lvSuppressLE notice 0
		log::lvSuppressLE warning 0
		log::lvSuppressLE info 0
		
		# make head of log
		set date [clock format [clock seconds] -format "%y/%m/%d %X"]
		log::log notice "=== ${date} Start archive full ==="

		# create important directory
		if [catch { file mkdir ${ARCHIVE_DIR} }] {
			log::log error "Can not create $ARCHIVE_DIR dir"
			fas_display_error "order_dir::2archive_full - Can not create [rm_root2 $ARCHIVE_DIR] dir" env
		}
		
		if [catch { file mkdir ${FULL_ARCHIVE_DIR} }] {
			log::log error "Can not create $FULL_ARCHIVE_DIR dir"
			fas_display_error "order_dir::2archive_full - Can not create [rm_root2 $FULL_ARCHIVE_DIR] dir" env 
		}

		if [catch { file mkdir ${SYNC_ARCHIVE_DIR} }] {
			log::log error "Can not create $SYNC_ARCHIVE_DIR dir"
			fas_display_error "order_dir::2archive_full - Can not create [rm_root2 $SYNC_ARCHIVE_DIR] dir" env 
		}

		if [catch { file mkdir ${LAST_ARCHIVE_DIR} }] {
			log::log error "Can not create $LAST_ARCHIVE_DIR dir"
			fas_display_error "order_dir::2archive_full - Can not create [rm_root2 $LAST_ARCHIVE_DIR] dir" env 
		}

		if [catch { file mkdir ${TARGZ_ARCHIVE_DIR} }] {
			log::log error "Can not create $TARGZ_ARCHIVE_DIR dir"
			fas_display_error "order_dir::2archive_full - Can not create [rm_root2 $TARGZ_ARCHIVE_DIR] dir" env 
		}

		set current_order_dir [rm_root2 $filename ]
		set current_full_archive_dir "${FULL_ARCHIVE_DIR}$current_order_dir"
		set current_last_archive_dir "${LAST_ARCHIVE_DIR}$current_order_dir"
		set current_sync_archive_dir "${SYNC_ARCHIVE_DIR}$current_order_dir"
		catch  {file delete -force -- $current_full_archive_dir}
		if [catch { file mkdir ${current_full_archive_dir} }] {
			log::log error "Can not create $current_full_archive_dir dir"
			fas_display_error "order_dir::2archive_full - Can not create [rm_root2 $current_full_archive_dir] dir" env
		}

		# copy order dir
		order_dir::copy_archive env $filename $current_full_archive_dir 

		# copy auther dir (/comp /template /etc..)
		# foreach dir [list "/comp" "/template" "/icons"]  {
# 			puts "$dir"
# 			catch {file copy -force -- "${ROOT}$dir" $current_full_archive_dir}
#		}
	
		# create symlink of auther dir
		foreach dir [list "/comp" "/template" "/icons"]  {
			if [catch { file link -symbolic "$current_full_archive_dir$dir" "${ROOT}$dir" } error ] {
				log::log error "can not create symbolic link $current_full_archive_dir$dir  in ${ROOT}$dir: $error "
			}
		}
	
		if { ($archive_type == "full") || ($archive_type == "all") } {
			# create full archive
			if [catch {exec bash -c "cd ${current_full_archive_dir}/ ;tar -cvzh -f ${dest_full_targz} ./ 2>/dev/null"}] {
				log::log error "error while created archive [rm_root2 ${dest_full_targz}]"
				# 			fas_display_error "order_dir::2archive_full - OK" env
			} else {
				log::log notice "[rm_root2 ${dest_full_targz}] created with success"
			}
		}
		

		if { ($archive_type == "sync") || ($archive_type == "all") } {
			set make_sync_archive 1
			# create sync dir and sync archive
			if { ![file exists $current_last_archive_dir]} {
				if [catch {file mkdir ${current_last_archive_dir} }] {
					log::log error "can not create [rm_root2 $current_last_archive_dir] dir"
					set make_sync_archive 0
				}
			}

			# sync is possible
			catch {file delete -force -- $current_sync_archive_dir}
			if [catch { file mkdir ${current_sync_archive_dir} }] {
				log::log error "Can not create [rm_root2 $current_sync_archive_dir] dir"
			}


			# first copy in sync_dir and in last_dir all new file from full_dir
			#set file_list [recursive_glob $current_full_archive_dir ""]
			if [catch {open ${current_sync_archive_dir}/files.all a} fdallfile] {
				log::log error "Can not open [rm_root2 ${current_sync_archive_dir}/files.delete]"
			} else {
				puts $current_full_archive_dir
				puts $fdallfile [recursive_glob $current_full_archive_dir ""]
				close $fdallfile
			}
			
			foreach file [recursive_glob $current_full_archive_dir ""] {
				set last_file "$current_last_archive_dir$file"
				set full_file "$current_full_archive_dir$file"
				set sync_file "$current_sync_archive_dir$file"

				if { ([file exists $last_file] != 1)  || ([md4::md4 -hex -file $last_file] != [md4::md4 -hex -file $full_file])} {
					catch {file mkdir [file dirname $last_file]}
					if [catch [file copy -force -- $full_file $last_file]] {
						log::log warning "Can not copy [rm_root2 $full_file] in [rm_root2 $last_file]"
					}
					if { $make_sync_archive == 1 } {
						catch {file mkdir [file dirname $sync_file]}
						if [catch {file copy -force -- $full_file $sync_file}] {
							log::log warning "Can not copy [rm_root2 $full_file] in [rm_root2 $sync_file]"
						}
					}
				}
			}
			
			# delete old file in last_dir
			catch {unset fdfile}
			if { $make_sync_archive == 1 } {
				if [catch {open ${current_sync_archive_dir}/files.delete a} fdfile] {
					log::log error "Can not open [rm_root2 ${current_sync_archive_dir}/files.delete]"
				}
			}
			foreach file [recursive_glob ${current_last_archive_dir} "" ] {
				set last_file "$current_last_archive_dir$file"
				set full_file "$current_full_archive_dir$file"
				set sync_file "$current_sync_archive_dir$file"
				if { ![file exists $full_file]} {
					if [catch {file delete -force -- $last_file}] {
						log::log error "Can not delete [rm_root2 $last_file]"
					} elseif [info exists fdfile] {
						puts $fdfile "$file"
					}
				}
			}
			if [info exists fdfile] {
				close $fdfile
			}
			# delete empty dir in last_dir
			recursive_delete_empty_dir $current_last_archive_dir ""

			# create sync_archive
			if { $make_sync_archive == 1 } {
				if [catch {exec bash -c "cd ${current_sync_archive_dir}/ ;tar -cvzh -f ${dest_sync_targz} ./ 2>/dev/null"}] {
					log::log error "error while created archive [rm_root2 ${dest_sync_targz}]"
					# 			fas_display_error "order_dir::2archive_full - OK" env
				} else {
					log::log notice "[rm_root2 ${dest_sync_targz}] created with success"
				}
			}

			# delete sync_dir and full_dir
			#		catch {file -delete -force "$current_sync_archive_dir"}
			#		catch {file -delete -force "$current_full_archive_dir"}
		} else {
			# no sync archive => juste copy full_dir in last_dir
			catch {file delete --force $current_last_archive_dir}
			if [catch { file mkdir ${LAST_ARCHIVE_DIR} }] {
				log::log error "Can not create $LAST_ARCHIVE_DIR dir"
				fas_display_error "order_dir::2archive_full - Can not create [rm_root2 $LAST_ARCHIVE_DIR] dir" env 
			}
			foreach file [glob -nocomplain -tails -directory ${current_full_archive_dir} * .?*] {
				if { ($file != ".") && ($file !="..")} {
					if [catch {file copy -force "${current_full_archive_dir}/$file" "${current_last_archive_dir}/"} error ] {
						log::log error "Can not copy [rm_root2 ${current_full_archive_dir}/$file] in last_dir" 
					}
				}
			}    
		}

	        # end of log
		flush $fdlog
		close $fdlog
		# todo
		# fas_display_error "order_dir::2archive_full - OK" env
		set message "[translate "Successful creation of the archive"]"
		# I try to display display the result directly in 
		# the message place of the directory display.
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		set _cgi_uservar(action) "edit_form"

		# I need to now the filetype of dir
		read_full_env $filename local_env
		set filetype [guess_filetype $filename conf local_env] 
		global conf
		display_file $filetype $filename local_env conf
		fas_exit
	}

	proc copy_archive { current_env filename dest_dirname } {
		upvar $current_env env
		
		fas_debug "order_dir::copy_archive - $current_env $filename $dest_dirname"

		# first copy order dir
		dir::copy_archive env $filename $dest_dirname

		# copy cond.order
		if [file exists "$filename/cond.order"] {
			order::copy_archive env "$filename/cond.order" $dest_dirname
		} else {
			log::log warning "File [rm_root2 $filename/cond.order] don't exists"
		}

		# copy main.order
		if [file exists "$filename/main.order"] {
			order::copy_archive env "$filename/main.order" $dest_dirname
		} else {
			log::log warning "File [rm_root2 $filename/main.order] don't exists"
		}
	}

	proc recursive_glob {  directory path } {
		set file_list [list]
		set current_dir "$directory$path"
		foreach file [ glob -nocomplain -tails -directory "$current_dir" * .?*] {
			if { ($file != ".") && ($file !="..")} { 
				if [file isdirectory "$current_dir/$file"] {
					set file_list [concat $file_list [recursive_glob $directory "$path/$file"]]
				} else {
					lappend file_list "$path/$file"
				}
			}
		}
		return $file_list
	}

	proc recursive_delete_empty_dir {directory path} {
		set current_dir "$directory$path"
		foreach file [glob -nocomplain -tails -types d -directory "$current_dir" * .?*] {
			if { ($file != ".") && ($file !="..")} {
				recursive_delete_empty_dir "$directory"  "$path/$file"
				catch {file delete "$current_dir/$file"}
			}
		}
	}

	proc recursive_copy_dir {current_env orig dest path} {
		upvar $current_env env
		set current_dir "$orig$path"
		foreach file [glob -nocomplain -tails -directory "$current_dir" * .?*] {
			if { ($file != ".") && ($file !="..")} {
				if [file isdirectory "$current_dir/$file"] {
					recursive_copy_dir env $orig $dest "$path/$file"
				} else {
					order::simple_copy_archive env "$current_dir/$file" $dest
				}
			}
		}
	}


	
}
