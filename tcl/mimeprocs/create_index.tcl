# no extensions for create_index
lappend filetype_list "create_index"

namespace eval create_index {

	# we will use swish-e 2.0.x for indexing
	set local_conf(index.swish-e) /usr/bin/swish-e

	# At the end of index I set it at 1.
	# I will use it when changing of state
	set done 0
	set level 0
	set errors 0
	set errstr ""


	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	proc init { } {
		variable done
		variable level
		variable errors
		variable errstr

		set done 0
		set level 0
		set errors 0
		set errstr ""
	}

	proc new_type { current_env filename } {
		# At the end of index, we will display edit_form
		# on the root_directory 
		set result fashtml
		# index type must appear only once after that when
		# "normal" filetype tests for it, it must not appear.
		# new_type is the only function executed when looking
		# for a file. So I must put there the setting of this
		# flag.
		variable done 
		set done 1
		fas_debug "create_index::new_type -> $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list edit_form]
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
		lappend env_list [list "create_index.file" "File in which the search index is stored." admin]
		return $env_list
	}

	# What is the name of the file for the index ?
	proc get_index_file { current_env } {
		upvar $current_env fas_env
		if { [info exists fas_env(create_index.file)] } {
			set index_file [file join [add_root $fas_env(create_index.file)] index.swish-e]
		} else {
			set root_directory "[add_root [fas_name_and_dir::get_txt4index_tree_start_dir fas_env]]"
			set index_file [file join [cache_filename create_index $root_directory fas_env -no_extension] index.swish-e]
		}
		return $index_file
	}

	# 
	# Let us do the indexing
	#
	proc 2fashtml { current_env filename } {
		fas_debug "create_index::2fashtml -------- STARTING FOR FILE $filename --------------"
		upvar $current_env fas_env
		variable local_conf

		# Always do again and again ?
		fas_depend::set_dependency 1 always

		# First, what do I index ?
		# I index the content of the txt4index cache
		set txt4index_directory [::txt4index_tree::get_txt4index_tree_dir fas_env]
		fas_debug "create_index::2fashtml - txt4index_directory -> $txt4index_directory"

		# I will put the index directly in the cache in the appropriate directory
		set index_file [get_index_file fas_env]

		# if the directory where I want to create the index does not exist, I create it
		set index_directory [file dirname $index_file]
		if { ![file exists $index_directory] } {
			catch {file mkdir $index_directory }
		}

		global _cgi_uservar
		unset _cgi_uservar

		if { ![file readable $txt4index_directory] } {
			set _cgi_uservar(message) "[translate "txt4index has not been done."]"
		} else {	      
			# indexing
			# we cd into the txt4index directory,
			# so that the result of a search will not start
			# with $fas_env(root_directory)/../cache/txt4index
			# FIXME: maybe that using $fas_env(root_directory)/../cache/txt4index
			# is not good
			set cwd [pwd]
			cd $txt4index_directory
			if { [catch { exec $local_conf(index.swish-e) -i . -f $index_file } error] } {
				set _cgi_uservar(message) "[translate "Problem while processing"] $index_file , [translate "search index creation with swish-e failed"] <BR>$error"
			} else {
				set _cgi_uservar(message) "[translate "Successfull text indexing."]"
			}
			cd $cwd
		}
		set _cgi_uservar(action) edit_form
		global conf
		display_file dir $filename fas_env conf
		fas_exit
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to edit a content. It must be a file."]</b></center></body></html>"
	}

}
