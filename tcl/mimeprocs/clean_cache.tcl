# no extensions for copy
lappend filetype_list clean_cache

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval clean_cache {
	# When the copy is done, I set it to 1.
	set done 0
	global INIT_ACTION
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		# When a txt is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result final
		# copy type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list treedir fashtml tmpl ]
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
		return $env_list
	}
	
	# This procedure will delete the whole cache and call the
	# edit_form on the current directory with a message
	proc 2final { current_env filename } {
		fas_debug "clean_cache::2final - Entering clean_cache"
		upvar $current_env fas_env
		global FAS_VIEW_CGI
		fas_depend::set_dependency 1 always

		set message  ""
		# First I must import the target name
		fas_debug_parray fas_env "clean_cache::2fashtml - is template_dir defined here ?"
		set CACHE_DIR_FLAG 0
		set cache_dir [add_root [fas_name_and_dir::get_cache_dir fas_env]]
		#if { [info exists fas_env(cache)] } {
		#	set cache_dir [add_root $fas_env(cache)]
		#	set CACHE_DIR_FLAG 1
		#} elseif { [info exists fas_env(root_directory)] } {
		#	set cache_dir [add_root $fas_env(root_directory)]
		#	set CACHE_DIR_FLAG 1
		#} 

		fas_debug "clean_cache::2fashtml - Ready to remove everything in $cache_dir"
		foreach path [glob -nocomplain [file join $cache_dir *] [file join $cache_dir {.[a-zA-Z]*}]] { 
		    # FIXME: this is only for the demo
		    #if { [file tail $path] != "txt4index" } {
			if { [catch {file delete -force $path } error ] } {
			#if { [catch {exec rm -R -f [file join $cache_dir *]} ] } 
				set message "clean_cache - [translate "Error while cleaning the whole cache"] - $error"
			} else {
				set message "[translate "Successful cleaning of cache"]"
			}
		    #}
		}
		# FIXME: only for the demo too, to keep htmlized .doc file
		# catch {file copy /usr/local/tmpl $cache_dir}

		# And now displaying the result
		if { [file isdirectory $filename] } {
			set dir $filename
		} else {
			set dir [file dirname $filename]
		}
		global _cgi_uservar
		unset _cgi_uservar
		set _cgi_uservar(message) "$message"
		global DEBUG
		if $DEBUG {
			set _cgi_uservar(debug) "$DEBUG"
		}
		set _cgi_uservar(action) "edit_form"
		# I need to now the filetype of dir
		read_full_env $dir local_env
		set filetype [guess_filetype $dir conf local_env] 
		global conf
		display_file $filetype $dir fas_env conf
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html
        # THIS PROCEDURE IS OBSOLETE AND SHOULD BE DELETED IF NOT USED 
	proc content2final { current_env content args } {
                error "clean_cache::content2final - OOOOppps finaly this code is used, do not remove it"
		return "<html><body><center><b>[translate "It is not possible to clean the cache on a content. It must be a file."]</b></center></body></html>"
	}
}
