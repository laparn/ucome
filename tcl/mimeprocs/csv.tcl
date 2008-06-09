# extension for txt
set conf(extension.csv) csv

lappend filetype_list csv

# And now all procedures for txt. How to translate into tmpl or html,
# how to display pure txt.
namespace eval csv {
	# What command to use to translate the txt in txt2ml
	# The -re option allows to convert relative links in absolute one
	# Finally, I put this function in htmf, then it is not useful in
	# the command line here.
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		# When a csv is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) tmpl
		# This is the default answer
		set result tmpl
		# Now there may be other cases

		if { ![catch {set action [fas_get_value action] } ] } {
			if { $action != "view" } {
				# there is an action. Is it done or not
				if { [set ${action}::done ] == 0 } {
					fas_debug "csv::new_type - action -> $action , action::done -> [set ${action}::done]"
					# the action was not processed
					set result $action
					return $result
				} ; # else I continue
			}
		}
		if { ![catch {set target [fas_get_value target -noe]}] } {
			# we are in the standard case nothing to do
			switch -exact -- $target {
				csv {
					# I throw an error I am at the end
					#error 1
					return ""
				}
				pdf  {
					# So I must take pdf.cgi_uservar informations
					fas_debug_parray fas_env "csv::new_type fas_env before down_stage_env"
					down_stage_env fas_env "pdf.cgi_uservar." 
					fas_debug_parray fas_env "csv::new_type fas_env after down_stage_env"
					set result comp
					# No need to write it, but it is more clear so
				}
				nomenu {
					set result fashtml
				}
				ori {
					set result csv
					#error 1
					return ""
				}
				# begin modif Xav
				rrooll -
				rool {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rool"
					set result comp
				}
				# end modif Xav
			}
		}
		# I need to be able to add an option for saying not
		# to go through tmpl
		set new_type_option [fas_get_value new_type_option -default standard]
		if { ( $result == "tmpl" ) && ( $new_type_option == "notmpl" ) } {
			set result fashtml
		}
		fas_debug "csv::new_type - result is $result"
		return $result
	}

	# List of possible types in which this file type may be converted
	# If this function is not defined, it is a final type that can
	# not be converted
	proc new_type_list { } {
		return [list tmpl fashtml]
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
		lappend env_list [list "csv.header_list" [list en "List of title of columns. List of elements separated by comma."] [list fr "Liste des titres des colonnes. Liste d'éléments séparées par des virgules."]]
		lappend env_list [list "csv.display_column" [list en "List of columns to display and display order. List of numbers separated by comma."] [list fr "Liste des titres des colonnes.Liste de nombres séparées par des virgules."]]
		#lappend env_list [list "session_dir" [list en "Directory with session variables files"] [list fr "Réoertoire contenant les fichiers des variables de session"]]
		return $env_list
	}

	# if this function exists, then it is possible to
	# create a new txt with the editor.
	proc may_create { } {
		return 0
	}

	proc mimetype { } {
		return "text/csv"
	}

	# This procedure will translate a txt into a tmpl
	# This is very arbitrary, as it may also be seen as pure 
	# html. It is just conf(newtype.txt) that will say
	# how it will be changed (in which cache directory it will be
	# written).
	proc 2tmpl { current_env args } {
		fas_debug "csv::2tmpl - $args"
		upvar $current_env env
		return "[eval 2fashtml env $args ]"
	}
	
	proc content2tmpl { current_env args } {
		fas_debug "csv::content2tmpl - $args"
		upvar $current_env env
		return "[eval content2fashtml env $args ]"
	}

	proc 2comp { current_env args } {
		fas_debug "csv::2comp - $args"
		upvar $current_env env
		# begin modif Xav
		#set tmp(content.content) "[extract_body [eval 2fashtml env $args ]]"
		if { [info exists ::_cgi_uservar(message)] } {
			set tmp(content.content) "<h1>$::_cgi_uservar(message)</h1>[extract_body [eval 2fashtml fas_env $args ]]"
		} else {	
			set tmp(content.content) "[extract_body [eval 2fashtml fas_env $args ]]"
		}
		# end modif Xav
		return "[array get tmp]"
	}

	# This procedure will translate a txt into html 

	# The dependencies are the following :
	#  - eventually $env(perso.tcl), $env(style)
	proc 2fashtml { current_env filename args } {
		fas_debug "csv::2fashtml - $args"
		upvar $current_env fas_env

		set real_filename [fas_name_and_dir::get_real_filename csv $filename fas_env]

		# I need to read the csv
		global auto_path
		lappend auto_path "/usr/lib/tcllib1.4"
		if {  [catch { package require struct; package require csv; }] } {
			return "csv::2fashtml - [translate "tcllib must be set up to benefit of csv type. Please set it up."]"
		}
		set final_lol [list]
		if { [catch {open $real_filename} fid] } {
			return "csv::2fashtml - [translate "Impossible to open "] [rm_root $real_filename]"
		} else {
			#::struct::matrix::matrix csv
			set full_file [read $fid]
			close $fid
			foreach line [split $full_file "\n"] {
				set current_list [csv::split $line ";"]
				# There is a misplaced ; at the end of the line in ocs files
				fas_debug "csv::2fashtml - showing lines - $current_list"
				lappend final_lol $current_list
			}
			#read2matrix $fid csv ";"
			#csv link -transpose csv_array
			fas_debug "csv.tcl::2fashtml - $final_lol"
		}


		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file

		# The output depends on some variables in the env files
		fas_depend::set_dependency $filename env

		# I need to get the list of the headers
		set header_list [split [fas_get_value csv.header_list -default "[list]" ] ","]

		# I create a list of columns to display
		set display_column_list [split [fas_get_value csv.display_column -default "[list]" ] ","]

		if { [llength $display_column_list] == 0 } {
			set ordered_header_list $header_list
			set ordered_final_lol $final_lol
		} else {
			# So I create the ordered lists
			# First the ordered_header_list
			set ordered_header_list ""
			set ordered_final_lol ""
			set header_length [llength $header_list]
			foreach dc $display_column_list {
				if { $dc < $header_length } {
					lappend ordered_header_list [lindex $header_list $dc]
				}
			}
			foreach row $final_lol {
				set ordered_row ""
				set row_length [llength $row]
				foreach dc $display_column_list {
					if { $dc < $row_length } {
						lappend ordered_row [lindex $row $dc]
					}
				}
				lappend ordered_final_lol $ordered_row
			}
		}
		# Getting the template
		set template_name [fas_name_and_dir::get_template_name fas_env "csv.template"]
		fas_depend::set_dependency $template_name file

		# I need a template
		atemt::read_file_template_or_cache "CSV_TEMPLATE" "$template_name"

		# Now I fill the header of the matrix
		if { [llength $header_list] > 0 } {
			atemt::atemt_set CURRENT_ROW -bl [atemt::atemt_set HEADER_ROW]
			foreach header_name $ordered_header_list {
				set content $header_name
				atemt::atemt_set CURRENT_ROW -bl [atemt::atemt_subst -insert -block HEADER_DATA CURRENT_ROW]
			}
		}
		atemt::atemt_set CSV_TEMPLATE -bl [atemt::atemt_subst -insert -block CURRENT_ROW CSV_TEMPLATE]

		# Now I read all lines and I display them
		set odd 0
		foreach list_of_elt $ordered_final_lol {
			if { $odd == 0 } {
				atemt::atemt_set CURRENT_ROW -bl [atemt::atemt_set EVEN_ROW]
			} else {
				atemt::atemt_set CURRENT_ROW -bl [atemt::atemt_set ODD_ROW]
			}
			foreach element $list_of_elt {
				set content $element
				atemt::atemt_set CURRENT_ROW -bl [atemt::atemt_subst -insert -block DATA CURRENT_ROW]
				fas_debug "csv.tcl::2fashtml - CURRENT_ROW --[atemt::atemt_set CURRENT_ROW]--"
			}
			atemt::atemt_set CSV_TEMPLATE -bl [atemt::atemt_subst -insert -block CURRENT_ROW CSV_TEMPLATE]
			set odd [expr 1 - $odd]
		}

		# That's it
		set final_html [atemt::atemt_subst -end CSV_TEMPLATE]
		return $final_html
	}

	proc get_title { filename } {
		return [::not_binary::get_title $filename]
	}
	
		
	proc content_display { current_env content } {
		return "[not_binary::content_display txt $content]"
	}
		
	proc display { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename txt]"
	}
	proc content { current_env filename } {
		# A procedure for just displaying the file in html directly
		upvar $current_env fas_env
		return "[not_binary::content fas_env $filename tmpl]"
	
	}

	proc 2txt4index { current_env filename } {
		upvar $current_env fas_env
		set real_filename [fas_name_and_dir::get_real_filename csv $filename fas_env]
		# Basically, the output depends on the input file
		fas_depend::set_dependency $real_filename file
		return "[not_binary::content fas_env $filename txt]"
	}
}
