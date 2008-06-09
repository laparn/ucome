namespace eval atemt {
	variable _atemt

	global ::DEBUG_PROCEDURES
	eval $::DEBUG_PROCEDURES
	# ATEMT - Advanced TEmplate Mechanism for Tcl
	# ATEMT - phonetically "attend" (wait!) in french
	# because a friend of mine said "Waooo - you saw the templates in phplib ? Hot !"
	# and I said him "Wait ! (attend !)"

	# append_result
	#   * block_name : name of the block
	#   * key : html or block
	#   * value : block name or html content
	proc append_result { block_name key value } {
		variable _atemt
		if { [info exists _atemt($block_name)] } {
			lappend _atemt($block_name) [list $key $value]
		} else {
			set _atemt($block_name) [list [list $key $value]]
		}
	}

	# append_html
	#   * block_name : name of the block with this html
	#   * html : html 
	proc append_html { block_name html } {
		append_result $block_name html $html
	}

	# append_block
	proc append_block { block_name name } {
		#puts "append_block $block_name $name"
		append_result $block_name block $name
	}
		
	# insert_result
	#   * block_name : name of the block
	#   * key : html or block
	#   * value : block name or html content
	proc insert_result { current_target block_name key value } {
		upvar $current_target _atemt
		if { [info exists _atemt($block_name)] } {
			set _atemt($block_name) [linsert $_atemt($block_name) 0 [list $key $value]]
		} else {
			set _atemt($block_name) [list [list $key $value]]
		}
	}

	# insert_html
	#   * current_target : target array
	#   * block_name : name of the block with this html
	#   * html : html 
	proc insert_html { current_target block_name html } {
		upvar $current_target target
		insert_result target $block_name html $html
	}

	# insert_block
	proc insert_block { current_target  block_name name } {
		#puts "insert_block $block_name $name"
		upvar $current_target target
		insert_result target $block_name block $name
	}

	# set_result
	#   * block_name : name of the block
	#   * key : html or block
	#   * value : block name or html content
	proc set_result { block_name key value } {
		variable _atemt
		set _atemt($block_name) [list [list $key $value]]
	}

	# set_html
	#   * current_target : target array
	#   * block_name : name of the block with this html
	#   * html : html 
	proc set_html {block_name html } {
		set_result $block_name html $html
	}

	# set_block
	proc set_block { block_name name } {
		set_result $block_name block $name
	}

	# split_template - transform the current template into a result
	# result is a lol with each list being :
	#   * [html|block] : flag saying if html or block
	#     * name of the block if it is a block
	#     * or pure html text if html, or a lol with the same format as this one
	# So the result is a graph, html being a leaf and block being a node.
	proc split_template { block_name template  } {
		#puts "Entering split_template $block_name $template"
		set END_STRING "<!-- *END +\[^> \]+ *-*>"
		variable _atemt
		if { [regexp "^(.*)($END_STRING)(.*)$" $template all start block_def end] } {
			#puts "Found block end -- start - $start -- block_def - $block_def -- end $end"
			# Putting the end of the block into the result
			insert_html _atemt $block_name $end
			# Now searching for the start
			set name [get_name $block_def]
			if { $name != "" } {
				set START_STRING "<!-- *BEGIN $name *-*>"
				insert_block _atemt $block_name $name
				if { [regexp "^(.*)($START_STRING)(.*)$" $start match start_html start_block end_block] } {
					#puts "split_template - found start of $name"
					#puts "----block is-------\n$end_block\n-------------"
					split_template $name $end_block
					split_template $block_name $start_html
				} else {
					# There is no start of block, so I consider that it goes till the start
					# I then need to take the current block and
					# to split again
					split_template $name $start
				}
			} else {
				# then I can not find the name of the block
				# this is certainly an error
				puts stderr "split_template - error - could not find block name - continuing"
				# I put the block_def as html
				# and I continue on the rest
				insert_html _atemt $block_name $block_def
				split_template $name $start
			}
		} else {
			# So I did not match anything (any block at the end).
			# Then it is a pure code in template
			insert_html _atemt $block_name $template
		}
	}

	proc get_name { block_def } {
		set START_STRING "BEGIN (\[^> \]*)\ *-*>"
		set END_STRING "END (\[^> \]*)\ *-*>"
		if [regexp $START_STRING $block_def all name] {
			return $name
		} elseif [regexp $END_STRING $block_def all name] {
			return $name
		} else {
			puts stderr "Could not find block name"
			return ""
		}
	}

	# 1.1. atemt_set
	# Usage :
	# 
	# =====================
	#
	# atemt_set block_name [html]
	# atemt_set block_name -bl [block_list]
	# =====================
	#
	# Allow to initialise a block with a content. By default, we consider
	# that html must be considered as a template and the resulting block
	# list created. With -bl option (block list), the content of the _attemt
	# variable (a block list) is directly given.
	# If there is only one argument, the content of _atemt (the block list)
	# is sent back.
	proc atemt_set { block_name args } {
		set arg_length [llength $args]
		switch $arg_length {
			0 { 
				variable _atemt
				fas_fastdebug {atemt::atemt_set - sending back $block_name}
				fas_fastdebug {atemt::atemt_set $block_name => $_atemt($block_name)}
				if { [info exists _atemt(${block_name})] } {
					fas_fastdebug {atemt::atemt_set - found $block_name}
					return $_atemt(${block_name})
				} else {
					fas_fastdebug {atemt::atemt_set - not found $block_name}
					return ""
				}
			}
			1 {
				split_template $block_name [lindex $args 0]
			}
			2 {
				variable _atemt
				set _atemt($block_name) [lindex $args 1]
			}
		}
	}
	# Usage :
	# atemt_subst [-all] [-no block_name] [-add|-insert|-subst] [-block block_name] [-end] [-vn] template_name
	# Options
	# -all : parse the whole template
	# -add|-insert|-subst : decide for the next block, the kind of substitution
	#                     : -subst is the default, the block is replaced
	#                     : by the substituted block
	#                     : -add will put the substituted block before the block
	#                     : -insert will put the substituted block after the block
	# -end : output the final template rendered. All block that where not 
	# -vn : do the work but without evaluating internal tcl variables
	#      : processed till there are canceled
	proc atemt_subst { args } {
		fas_fastdebug {--atemt::atemt_subst $args}
		variable _atemt
		global no_list
		global subst_list
		global type_subst_list
		# The list of the blocks not to substitute
		set no_list ""
		# The list of blocks to substitute
		set subst_list ""
		# A list of the same length than subst_list and giving
		# the type of substitution for each block
		set type_subst_list ""
		# ALL_FLAG : 1 all html and blocks will be substituted
		# except those in the no_list
		set ALL_FLAG 0
		# ALL_BLOCK_FLAG : 1 all blocks will be recursively substituted
		# except those in the no_list
		set ALL_BLOCK_FLAG 0
		# SUBST_FLAG used to determine the type of substitution for
		# the next block (add, insert or subst)
		set SUBST_FLAG subst
		# END_FLAG : 1 return from the function the current template
		# reconstructed after substitution. Only html is displayed.
		set END_FLAG 0

		# Sometimes I just want a replacement WITHOUT EVALUATION
		# of the tcl variables in the block
		set NO_EVALUATION 0
		# option will be -vn (valuation no)

		# The name of the template to substitute
		set template_name ""

		set state "parse_arg"
		foreach arg $args {
			switch -exact -- $state {
				parse_arg {
					switch -glob -- $arg {
						-al* {
							set ALL_FLAG 1
						}
						-ab* {
							set ALL_BLOCK_FLAG 1
						}
						-n* {
							set state NO
						}
						-b* {
							set state BLOCK
						}
						-ad* {
							set SUBST_FLAG add
						}
						-i* {
							set SUBST_FLAG insert
						}
						-s* {
							set SUBST_FLAG subst
						}
						-e* {
							set END_FLAG 1
						}
						-vn* {
							set NO_EVALUATION 1
						}
						default {
							set template_name $arg
						}
					}
				}
				NO {
					lappend no_list $arg
					set state parse_arg
				}
				BLOCK {
					lappend	subst_list $arg
					lappend type_subst_list $SUBST_FLAG
					set SUBST_FLAG subst
					set state parse_arg
				}
			}
		}
		#fas_debug "--atemt::atemt_subst finished to parse argument"
		#fas_debug "--atemt::atemt_subst subst_list $subst_list"
		#fas_debug "--atemt::atemt_subst type_subst_list $type_subst_list"
		#fas_debug "--atemt::atemt_subst going through  $_atemt($template_name)"
		#fas_debug_parray _atemt
		
		# So now I am going to do the substitution for the necessary blocks
		set result ""
		if { [info exists _atemt($template_name)] } {
			set index 0
			foreach block_list $_atemt($template_name) {
				set key [lindex $block_list 0]
				#fas_debug "--atemt::atemt_subst - processing $key"

				if { $key == "html" } {
					#fas_debug "--atemt::atemt_subst - processing html block"
					if $ALL_FLAG { 
						# Do the substitution
						# uplevel 2 as I will call it from atemt_subst
						# I have now a namespace, I then add 1
						#lappend result  [list html [uplevel 1 subst [list $value]]]
						if { !$NO_EVALUATION } {
							# Trying to suppress [ in value
							set value [lindex $block_list 1]
							regsub -all {\[} $value {\\[} value
							lappend result  [list html [uplevel 1 subst [list $value]]]
							#fas_debug "--atemt::atemt_subst - done substitution on $value"
				
						} else {
							lappend result $block_list
							#fas_debug "--atemt::atemt_subst - no substitution"
						}
					} else  {
						# else I do not change the element
						# there is nothing to do
						lappend result $block_list
						#fas_debug "--atemt::atemt_subst - no substitution"
					}
				} else {
					# So it is a block, first do I have to replace it ?
					# if it is not in the no_list, perhaps,
					# then if there is ALL_BLOCK_FLAG or it is
					# in the subst_list yes.
					set value [lindex $block_list 1]
					#fas_debug "--atemt::atemt_subst - processing block $value"
					if { [lsearch $no_list $value] < 0 } {
						# it is not in the no_list
						set subst_pos [lsearch $subst_list $value]
						#fas_debug "--atemt::atemt_subst - subst_pos $subst_pos"
						if { $subst_pos < 0 } {
							set subst_type subst
						} else {
							set subst_type [lindex $type_subst_list $subst_pos]
						}
						#fas_debug "--atemt::atemt_subst - subst_type $subst_type"
						if { $ALL_BLOCK_FLAG || ( $subst_pos > -1 ) } {
							# Now I know that I must do the substitution
							#fas_debug "--atemt::atemt_subst - block processing doing the substitution"
							if { $subst_type == "add" } {
								#fas_debug "--atemt::atemt_subst - add block $value in $template_name"
								lappend result $block_list
							}
							if { !$NO_EVALUATION } {
								foreach current_block_list [subst_block $value] {
									#fas_debug "--atemt::atemt_subst - add block $current_block_list"
									lappend result $current_block_list
								}
							} else {
								# no evaluation required
								foreach current_block_list [subst_block $value -vn] {
									#fas_debug "--atemt::atemt_subst - add block $current_block_list without evaluation"
									lappend result $current_block_list
								}
							}
								
							if { $subst_type == "insert" } {
								#fas_debug "--atemt::atemt_subst - insert block $block_list"
								lappend result $block_list
							}
						} else {
							# it is not substituted I keep the values
							#lappend result [list $key $value]
							lappend result $block_list
						}
					} else {
						# it is in the no list I do not substitute
						#fas_debug "--atemt::atemt_subst - block $value not substituted"
						#lappend result [list $key $value]
						lappend result $block_list
					}
				}
				incr index
			}
		} else {
			fas_fastdebug {--atemt::atemt_subst Problem no element $template_name in _atemt}
		}
		if { $END_FLAG } {
			set final_result ""
			foreach block_list $result {
				set key [lindex $block_list 0]
				if { $key == "html" } {
					set value [lindex $block_list 1]
					append final_result $value
				}
			}
			set result $final_result
			init
		}
		return $result
	}

	# Equivalent to the END statement of atemt_subst but in a more direct way
	proc atemt_subst_end { template_name } {
		fas_fastdebug {--atemt::atemt_subst_end $template_name}
		variable _atemt
		
		# So now I am going to do the substitution for the necessary blocks
		if { [info exists _atemt($template_name)] } {
			set final_result ""
			foreach block_list $_atemt($template_name) {
				set key [lindex $block_list 0]
				if { $key == "html" } {
					set value [lindex $block_list 1]
					append final_result $value
				}
			}
			set result $final_result
			init
		}
		return $result
	}

	# Just a procedure for atemt_subst -insert -block but simpler
	# atemt_subst_insert block1 block2 template_name
	# Both block1 and block2 will be inserted
	proc atemt_subst_insert { args } {
		fas_fastdebug {--atemt::atemt_subst $args}
		variable _atemt
		set subst_list [lrange $args 0 end-1]
		set template_name [lindex $args end]
		#fas_debug "--atemt::atemt_subst_insert subst_list_insert $subst_list"
		#fas_debug "--atemt::atemt_subst_insert going through  $template_name"
		
		# So now I am going to do the substitution for the necessary blocks
		set result ""
		if { [info exists _atemt($template_name)] } {
			set index 0
			foreach block_list $_atemt($template_name) {
				set key [lindex $block_list 0]
				#fas_debug "--atemt::atemt_subst_insert- processing $key"

				if { $key == "html" } {
					lappend result $block_list
				} else {
					# So it is a block, first do I have to replace it ?
					set value [lindex $block_list 1]
					set subst_pos [lsearch $subst_list $value]
					#fas_debug "--atemt::atemt_subst_insert- subst_pos $subst_pos"
					if { $subst_pos > -1  } {
						# Now I know that I must do the substitution
						#fas_debug "--atemt::atemt_subst_insert - block processing doing the substitution"
						foreach current_block_list [subst_block $value] {
							#fas_debug "--atemt::atemt_subst_insert - add block $current_block_list"
							lappend result $current_block_list
						}
						# And I append the block again (it was an insertion)
						lappend result $block_list
					} else {
						# It must no be substituted
						#fas_debug "--atemt::atemt_subst_insert - block $value not substituted"
						#lappend result [list $key $value]
						lappend result $block_list
					}
				}
				incr index
			}
		} else {
			fas_fastdebug {--atemt::atemt_subst_insert Problem no element $template_name in _atemt}
		}
		return $result
	}

	proc subst_block { template_name args } {
		# Sometimes I just want a replacement WITHOUT EVALUATION
		# of the tcl variables in the block
		set NO_EVALUATION 0
		# option will be -vn (valuation no)
		variable _atemt
		set result ""


		if { [llength $args] != 0 } {
			set NO_EVALUATION 1
		}
		#fas_debug "--atemt::subst_block - Entering subst_block - $template_name $args"
		#fas_debug "--atemt::subst_block - $template_name => $_atemt($template_name)"
		if { [info exists _atemt($template_name)] } {
			foreach block_list $_atemt($template_name) {
				set key [lindex $block_list 0]
				set value [lindex $block_list 1]

				if { $key == "html" } {
					# Do the substitution
					# uplevel 2 as I will call it from atemt_subst
					# Due to namespace, it is now uplevel 3
					#lappend result [list html [uplevel 2 subst [list $value]]]
					if { !$NO_EVALUATION } {
						# catch { lappend result [list html [uplevel 2 subst [list $value]]] }
						# I try to suppress [ in the value
						regsub -all {\[} $value {\\[} value
						if { [catch { lappend result [list html [uplevel 2 subst [list $value]]] } subst_block_error ] } {
							lappend result [list html "<br />Error while substituting $template_name : $subst_block_error<br />"]
						}
					} else {
						lappend result [list html $value]
					}
				} else {
					lappend result [list $key $value]
					# Finally no recursive behaviour
					# append result [subst_block $value]
				}
			}
		}
		#fas_debug "--atemt::subst_block - $result"
		return $result
	}

	# Get a list of all blocks in the template
	proc get_block_list { template_name } {
		fas_fastdebug {--atemt::atemt_subst $args}
		variable _atemt
		return [array names _atemt]
	}

	# Reading the block_name lol directly in cache_filename	
	proc get_cache_template { block_name cache_filename } {
		variable _atemt
		set _atemt($block_name) ""
		if { [file readable $cache_filename] } {
			if { ![catch { open $cache_filename } fid ] } {
				array set _atemt [read $fid]
				close $fid
			}
		}
	}

	# Directly write a template in a cache file to speed up
	# the processing of template
	proc write_cache_template { block_name cache_filename } {
		variable _atemt
		if { ![catch {open $cache_filename w} fid] } {
			#puts "[array get _atemt]"
			puts $fid [array get _atemt]
			close $fid
		} else {
			# I silently say nothing
			#puts "Impossible to open $cache_filename for writing"
		}
	}
	
	# Reading a template into a file.
	proc read_file_template { block_name template_filename } {
		variable _atemt
		if { [catch {
			set fid [open $template_filename]
			set tmpl [read $fid]
		}] } {
			error "atemt::read_file_template - Problem while reading template $template_filename"
		} else {
				split_template $block_name $tmpl
				close $fid
		}
	}

	# Reading a template or getting a cache
	# cache will have .cache extension
	proc read_file_template_or_cache { block_name template_name } {
		# First getting the template file
		# Is there a cache file
		main_log "Using template [rm_root $template_name]"
		if { [ file readable "${template_name}.cache" ] } {
			if { [ file mtime "${template_name}.cache"] > [file mtime ${template_name}] } {
				# OK I can use the cache file
				get_cache_template $block_name "${template_name}.cache"
			} else {
				read_file_template $block_name $template_name
				write_cache_template block_name "${template_name}.cache"
			}
		} else {
			read_file_template $block_name $template_name
			write_cache_template $block_name "${template_name}.cache"
		}
	}

	# I trow everything out, and start again
	proc init { } {
		variable _atemt
		#catch { unset _atemt }

		array unset _atemt 
	}
	
	proc exists { block_name } {
		variable _atemt
		return [info exists _atemt($block_name)]
	}
}
