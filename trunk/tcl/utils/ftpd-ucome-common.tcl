source ${FAS_PROG_ROOT}/fas_debug_procedures.tcl
source ${FAS_PROG_ROOT}/fas_basic_proc.tcl
package require md5
#source ${FAS_PROG_ROOT}/md5.tcl
source ${FAS_PROG_ROOT}/atemt.tcl
source ${FAS_PROG_ROOT}/fas_env.tcl
source ${FAS_PROG_ROOT}/fas_name_and_dir.tcl
source ${FAS_PROG_ROOT}/fas_menu.tcl
source ${FAS_PROG_ROOT}/fas_display.tcl
source ${FAS_PROG_ROOT}/fas_session.tcl
source ${FAS_PROG_ROOT}/fas_depend.tcl
source ${FAS_PROG_ROOT}/fas_user.tcl
source ${FAS_PROG_ROOT}/fas_domp.tcl
source ${FAS_PROG_ROOT}/mimeprocs/password.tcl

source ${FAS_PROG_ROOT}/fas_debug.tcl
set DEBUG 1
array set fas_env [list]

proc bgerror {args} {
    global errorInfo
    # modif Xav puts stderr "bgerror: [join $args]"
	if { [ catch { puts stderr "bgerror: [join $args]" } ] } {
		puts stderr "bgerror: error while calling bgerror !"
	}
    puts stderr $errorInfo
}

proc ftplog {level text} {
	# begin modif Xav
	if {[string equal $level note]} {
		set level notice
	}

	log::Puts $level $text

	# try to log all events into "/tmp/ftpd-ucome.log"
	if { [ catch {
		set logfile [open "/tmp/ftpd-ucome.log" "w"]
		fconfigure $logfile -translation { auto auto }
		puts -nonewline $logfile "${level} ${text}"
		#flush $logfile
		catch { close $logfile }
	} errmsg ] } {
		log::Puts warning $errmsg
	}
	# end modif Xav
}

proc file_auth { user filename read_or_write } {
	::ftpd::Log debug "file_auth - user $user - filename $filename - read_or_write - $read_or_write"
	set real_filename [normalise [add_root $filename]]

	# Is ROOT at start of the path ?
	if { ![check_root $real_filename ] } {
		return 0
	}

	# Now is .mana there in ?
	if { ![check_ftp_path $real_filename] } {
		return 0
	}

	#
	if { $read_or_write == "read" } {
		set action "view"
	} else {
		set action "edit"
	}
	# I need to get the fas_env variables
	read_full_env $real_filename fas_env

	# Now I need to set the user
	set ::fas_user::name $user

	::ftpd::Log debug "file_auth - answer : [::fas_user::allowed_action $real_filename $action fas_env]"

	return [::fas_user::allowed_action $real_filename $action fas_env]
}

proc user_auth { name password } {
	# I need to confirm the authentification
	# I get the env for ROOT
	global ROOT

	::ftpd::Log debug "user_auth - name $name - password $password"
	# I need to get the fas_env variables
	read_full_env $ROOT fas_env

	::ftpd::Log debug "user_auth - answer => [::fas_user::check_password fas_env $name $password]"
	return [::fas_user::check_password fas_env $name $password]
}

proc fakefs { cmd path args } {
    # Use the standard unix fs, i.e. "::ftpd::fsFile::fs", but rewrite the incoming path
    # to stay in the /tmp directory.
    # Except for the . files. I do not want people to be able to manipulate
    # properties directly. They could change the rights !

	set path [normalise [add_root $path]]
	if { ![check_root $path] || ![check_ftp_path $path] } {
		::ftpd::Log note "Trial for accessing unallowed $path"
		foreach { style outchan } $args break
		#{
			puts $outchan "530 Trial for accessing unallowed $path"
			::ftpd::Log "->530 Trial for accessing unallowed $path"
		#}
	} else {
		#set path [file join $ROOT [file tail $path]]
		::ftpd::Log debug "fakefs::path => $path ; command => [linsert $args 0 $cmd $path]"
		puts "fakefs::cmd is $cmd"
		puts "fakefs::path is $path"
		puts "fakefs::args is $args"

		switch -exact -- $cmd {
			"dlist" {
				global tcl_platform
				# Now the dlist	    
				foreach { style outchan } $args break
				#{
					puts "fakefs::outchan is $outchan"

					# Attempt to get a list of all files (even ones that start with .)
					if { [file isdirectory $path] } {
						set path1 [file join $path *]
					} else {
						set path1 $path
					}

					# Get a list of all files that match the glob pattern
					set fileList [lsort -unique [glob -nocomplain $path1]]

					switch -- $style {
						nlst {
							foreach f [lsort $fileList] {
								if { [string equal [file tail $f] "."] || \
									 [string equal [file tail $f] ".."] } {
									continue
								}
								puts $outchan "$f"
								::ftpd::Log debug "->putting $f on $outchan"
							}
						}
						list {
							foreach f [lsort $fileList] {
								file stat $f stat
								if { [string equal $tcl_platform(platform) "unix"] } {
									set user [file attributes $f -owner]
									set group [file attributes $f -group]

									puts $outchan [format "%s %3d %s %8s %11s %s %s" \
										[::ftpd::fsFile::PermBits $f $stat(mode)] $stat(nlink) \
										$user $group $stat(size) \
										[::ftpd::fsFile::FormDate $stat(mtime)] [file tail $f]]
									::ftpd::Log debug "->putting [format "%s %3d %s %8s %11s %s %s" \
										[::ftpd::fsFile::PermBits $f $stat(mode)] $stat(nlink) \
										$user $group $stat(size) \
										[::ftpd::fsFile::FormDate $stat(mtime)] [file tail $f]] on $outchan"
								} else {
									puts $outchan [format "%s %3d %11s %s %s" \
									[::ftpd::fsFile::PermBits $f $stat(mode)] $stat(nlink) \
									$stat(size) [::ftpd::fsFile::FormDate $stat(mtime)] \
									[file tail $f]]
									::ftpd::Log debug "-> putting [format "%s %3d %11s %s %s" \
										[::ftpd::fsFile::PermBits $f $stat(mode)] $stat(nlink) \
										$stat(size) [::ftpd::fsFile::FormDate $stat(mtime)] \
										[file tail $f]] on $outchan"
								}
							}
						}
						default {
							::ftpd::Log note "Unknown list style <$style>"
						}
					}
				#}
			}
			default {
				# modif Xav eval [linsert $args 0 ::ftpd::fsFile::fs $cmd $path]
				# puts "fakefs::going through ::ftpd::fsFile"
				eval [list ::ftpd::fsFile::fs $cmd $path] $args
			}
		}
	}
}

# Rewrite of the ftpd lib CWD.
# In konqueror, I think that they wait for an error if they do a
# cwd on a file. It allows them to determine if a file with a 
# strange extension is a file or a directory => I must use add_root
# to have the "real" file position and test file or directory.
# and then and I can not put that in ftpd.tcl which should be
# ::ftpd::command::CWD --
#
#       Handle the CWD ftp command.  Change the current working directory.
#
# Arguments:
#       sock -                   The channel for this connection to the ftpd.
#       list -                   The arguments to the CWD command.
#
# Results:
#       None.
#
# Side Effects:
#       Changes the data(cwd) to the appropriate directory.

proc ::ftpd::command::CWD {sock list} {
    upvar #0 ::ftpd::$sock data

    set relativepath [lindex $list 0]

    if {[string equal $relativepath .]} {
		puts $sock "250 CWD command successful."
		::ftpd::Log debug "250 CWD command successful."
		return
    }

    if {[string equal $relativepath ..]} {
		set data(cwd) [file dirname $data(cwd)]
		puts $sock "250 CWD command successful."
		::ftpd::Log debug "250 CWD command successful."
		return
    }

    # Either it is really a directory, it's fine, or
    # it is not. It must be said.
	set tmp_cwd [file join $data(cwd) $relativepath]
	if { [file isdirectory [add_root $tmp_cwd]] } {
		set data(cwd) $tmp_cwd
		puts $sock "250 CWD command successful."
		::ftpd::Log debug "->250 CWD command successful."
	} else {
		# it is not a directory, this is not fine
		# I do not change cwd
		puts $sock "550 CWD not a directory"
		::ftpd::Log debug "->550 CWD not a directory"
	}
	return
}

::ftpd::config -logCmd ftplog -authUsrCmd user_auth -authFileCmd file_auth -fsCmd fakefs
set ::ftpd::port 7777 ; # Listen on user port

#modif Xav
set ::ftpd::ip 172.20.0.2

::ftpd::server
vwait forever
