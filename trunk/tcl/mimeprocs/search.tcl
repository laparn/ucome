# no extensions for search_form
lappend filetype_list search

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval search {

	# we will use swish-e 2.0.x for searching
	set local_conf(search.swish-e) /usr/bin/swish-e

	# At the end of the search I set it at 1.
	# I will use it when changing of state
	set done 0

	global DEBUG_PROCEDURES INIT_ACTION
	eval $DEBUG_PROCEDURES
	eval $INIT_ACTION

	proc new_type { current_env filename } {
		set result tmpl
		variable done 
		set done 1
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list tmpl]
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
		lappend env_list [list "search.template" "Html file with special tags for displaying the result of a search action." webmaster]
		return $env_list
	}

	proc 2tmpl { current_env filename } {
		upvar $current_env fas_env
		return "[2fashtml fas_env $filename]"
	}
       

	# This procedure will create the html result of a search
	proc 2fashtml { current_env filename } {
		upvar $current_env fas_env
		fas_debug "search::2fashtml"
		# First the dependencies :
		fas_depend::set_dependency 1 always

    		global _cgi_uservar
    		#if { [catch { set search_string [cgi_import search_string] } error ] }
		if { ![info exists _cgi_uservar(search_string)] } {
    			set message "search.tcl::2fashtml - search string doesn't exist"
    			#unset _cgi_uservar
			return "$message"
    		} else {
			set search_string $_cgi_uservar(search_string)
			set index_file [::create_index::get_index_file fas_env]
			fas_debug "search::2fashtml: index file is $index_file"
			set results [ perform_search $search_string "$index_file" ]
			fas_debug "search::2fashtml: result: $results"
			return [process_results fas_env $search_string $results]
		}
	}

	proc process_results { current_env query results } {
		upvar $current_env fas_env
		# Template loading
		set template_name [fas_name_and_dir::get_template_name fas_env "search.template"]
		atemt::read_file_template_or_cache "SEARCH_RESULTS" "$template_name"
		fas_depend::set_dependency $template_name file

		# Base substitution
	        atemt::atemt_set HEAD_TITLE "[translate "Search results"]"
                atemt::atemt_set TOP_TITLE "[translate "Search results for "]"
		atemt::atemt_set QUERY $query
		
		set atemt::_atemt(SEARCH_RESULTS) [atemt::atemt_subst -block HEAD_TITLE -block TOP_TITLE -block QUERY SEARCH_RESULTS]
		foreach result $results {
			foreach { score file title bytes } $result {
				set tmp_filename $file
			
				regexp {^\./(.*?)$} $file match tmp_filename
				set filename [file join [fas_name_and_dir::get_txt4index_tree_start_dir fas_env] $tmp_filename]
				fas_debug "search::process_results - score $score - file $file - tmp_filename $tmp_filename - filename $filename"
				# get the query word inside its context
				set context_lines [get_context fas_env $query "$filename"]
				set context_line_before [lindex $context_lines 0]
				set context_line [lindex $context_lines 1]
				set context_line_after [lindex $context_lines 2]
				
				# we remove the leading //./ and the trailing && from the file
				set url "fas:$filename"

				set score "[expr $score / 10]%"
				set atemt::_atemt(SEARCH_RESULTS) [atemt::atemt_subst -insert -block ROW SEARCH_RESULTS]
			}
		}
		
		# final -end substitution
		set final_html [atemt::atemt_subst -end SEARCH_RESULTS]

		# return the result
		return $final_html
	}

	proc get_context { current_env query filename } {
		upvar $current_env fas_env
	        # FIXME
		set realfile_name "[add_root $filename]"
		fas_debug "search::get_context - looking for $filename in $realfile_name"
		
		if { [catch { open $realfile_name } fid ] } {
			return "Error while looking for $realfile_name"

			#fas_display_error "search::get_resume: cannot open file $realfile_name<br>$fid"
		}
		set data [list]
		while { ! [eof $fid] } {
			lappend data [gets $fid]
		}
		close $fid

		# build a list of the query word we will search in the data
		set query_list [ list ]
		foreach word $query {
			# remove of the eventual *,(,) that are allowed for swish-e search
			set query_word [ string trim $word "\*()" ]
			# Remove swish-e reserved words (and, or, not)
			if { $query_word != "and" && $query_word != "or" && $query_word != "not" } then {
				lappend query_list $query_word
			}
		}			

		set i 0
		set idx 0
		set keyword ""
		set no_line_found 1
		while { $no_line_found && $i < [ llength $query_list ] } {
		    set keyword [ lindex $query_list $i ]
		    foreach line $data {
			if { [string match -nocase "*$keyword*" $line] } {
			    set no_line_found 0
			    break
			}
			incr idx
		    }
		    #	set idx [ lsearch -glob $data "*$keyword*" ]
		    #if { $idx != -1 } {
			# line found
			#set no_line_found 0
			#} else {
			    # search next keyword
			    if { $no_line_found == 1} {
				incr i
				set idx 0
			    }
			#}
		    }
		     
		# No keyword found
		if { $no_line_found } {
		    return [list "###" [translate "Nothing to display"] "###"]
		}

		# get the line before, the line with the query word, and the line after
		set LINES_BEFORE 1
		set LINES_AFTER 1
		set lines [list]
		for { set i [ expr $idx - $LINES_BEFORE ] } { $i <= [ expr $idx + $LINES_AFTER ] } { incr i } {
			lappend lines [ lindex $data $i]
		}

		return $lines
#		regsub -all -nocase "($keyword)" $lines $HIGHLIGHT_TYPE lines
#		return "$HIGHLIGHT_BEFORE$lines$HIGHLIGHT_AFTER"

	}


	# Launch SWISH and return a list w/ all results
	proc perform_search { query swishdb } {
		set S "\[^ ]"
		set ret [ list ] 

		variable local_conf
		if { [ catch { open "| $local_conf(search.swish-e) -f $swishdb -w \"$query\" -m 0" r } fid  ] } {
			fas_debug "search::perform_search: swish-e error !<br>$fid"
			return [list]
		} else {
			fas_debug "search::perform_search: swish-e found something !"
			while { ![eof $fid] } {
				set line [ gets $fid ]
				if [ regexp "^($S+) ($S+) \"($S+)\" ($S+)" $line match score furl doctitle bytes ] {
					lappend ret $line
				}
			}
		}
		return [lsort -integer -decreasing -index 0 $ret]
	}

	# This procedure will translate a string in txt2ml format into html 
	proc content2fashtml { current_env content args } {
		return "<html><body><center><b>[translate "It is not possible to search a content. It must be a filename."]</b></center></body></html>"
	}
}
