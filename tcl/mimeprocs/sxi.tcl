# extension for openoffice
set conf(extension.sxi) sxi

lappend filetype_list sxi

# And now all procedures for todo. How to translate into a comp,
namespace eval sxi {
	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	set base_convert "/usr/local/OpenOffice.org1.1.0/program/python ${FAS_PROG_ROOT}/utils/sxiconvert.py"
	set local_conf(convert_html) "${base_convert} --html"
	set local_conf(convert_pdf) "${base_convert} --pdf"
	set local_conf(convert_txt) "${base_convert} "
	set local_conf(ootype) "sxi"

	set local_conf(autocache_dirname) "autocache"

	global OPENOFFICE_PROCEDURES
	eval $OPENOFFICE_PROCEDURES

	# No luck, in the case of the presentations,
	# it is slightly more complicated :
	#  * I must put the presentation in an isolated directory,
	#  * Show that all html files there are in fact tmpl,
	#  * have the "First page" link jumping at the file.sxi .
	# It should do it.
	proc 2fashtml { current_env filename args } {
		upvar $current_env fas_env
		variable local_conf

		set real_filename [fas_name_and_dir::get_real_filename $local_conf(ootype) $filename env]
		fas_depend::set_dependency $real_filename file

		# This function will take a sxi and convert it into an autocache file
		# Do I have an autocache ? Do I use it ?
		# For html and sxi, autocache_filename is special
		set autocache_filename [get_sxi_autocache_filename $real_filename]
		set local_conf(autocache_dirname) "autocache/[file tail $real_filename]"
		fas_depend::set_dependency $autocache_filename

		# Does it exist ?
		set AUTOCACHE_EXIST 0
		if { [file readable $autocache_filename] } {
			if { [info exists fas_env(always_autocache)] } {
				if $fas_env(always_autocache) {
					set AUTOCACHE_EXIST 1
				}
			}
			if { [file mtime $autocache_filename] > [file mtime $real_filename] } {
				set AUTOCACHE_EXIST 1
			}
		}

		if { !$AUTOCACHE_EXIST } {
			# If autocache is not good, I work it out again
			# Trying oo
			# Does the directory exists 
			set autocache_dir [file dirname $autocache_filename]
			if { ![file readable $autocache_dir] } {
				if { [catch {file mkdir $autocache_dir; file attributes  $autocache_dir -permissions "ugo+rwx"} error] } {
					set content "<h1>$local_conf(ootype)::2fashtml - [translate "could not create autocache directory"] [rm_root $autocache_dir]</h1><pre>$error</pre>"
					return $content
				}
			}
					
			variable local_conf
			# All filenames must be absolute
			set command "$local_conf(convert_html) $real_filename $autocache_filename"

			fas_debug "$local_conf(ootype)::2fashtml - command => $command"
			if { [catch {eval exec $command} error] } {
				# An error occured
				return "<h1>$local_conf(ootype)::2fashtml - [translate "Problem while converting an OpenOffice.org file into html - maybe OpenOffice.org is not set up or a password was put on the file ?"]</h1><p>$real_filename -> $autocache_filename</p><pre>$error</pre>"
			} else {
				# I need to clean the html.
				if { [ catch {open $autocache_filename} fid ] } {
					# I ignore the error
				} else {
					set html_content [read $fid]
					close $fid
					# Now cleaning
					# First thing to do add autocache at start of all
					# img src tag
					set html_result [process_html $html_content {<[Ii][Mm][Gg][^>]+?>} {(.*[Ss][Rr][Cc]=["'])([^ >]+)(["'].*)}]
					set html_result [process_html $html_result {<[Aa][^>]+?>} {(.*[Hh][Rr][Ee][Ff]=["'])([^ >]+)(["'].*)}]
					# But there is the first page problem, converting it back
					# I must replace "fas:[rm_root $autocache_filename]" by
					# [rm_root $real_filename] ?
					#regsub -all "\"fas:[rm_root $autocache_filename]\"" html_result "fas:[rm_root $real_filename]" html_result
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *position:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *top:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *bottom:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *width:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Dd][Ii][Vv][^>]+?>} { *height:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Ss][Pp][Aa][Nn][^>]+?>} { *float:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Ss][Pp][Aa][Nn][^>]+?>} { *width:[^;]+;} {}]
					set html_result [clean_html $html_result {<[Ss][Pp][Aa][Nn][^>]+?>} { *height:[^;]+;} {}]
					#set html_result $html_content
					# And storing the result
					if { ![ catch {open $autocache_filename w} fid ] } {
						puts $fid $html_result
						close $fid
					} else {
						return "$local_conf(ootype)::2fashtml - [translate "Could not open autocache file for writing : "] [file tail $autocache_filename]<BR><pre>$fid</pre>"
					}
				}
			}
			# else it is OK, I can extract auto_cache now
		}


		if { [catch {set content [get_sxi_autocache_content $real_filename]} error ] } {
			return "$local_conf(ootype)::2fashtml - [translate "Automatic conversion is not yet handled, please put a file named as "] [file tail $autocache_filename] [translate "in the current directory. Thanks."]<BR>$error"
		}

		# Now extracting the body
		return [extract_body $content]
	}

	# A single procedure to change the url to match autocache ones
	# Strongly inspired from to_right_url in fashtml.tcl
	proc to_autocache_url { str re } {
		set result ""
		variable local_conf

		if {[regexp $re $str match start url end]} {
			if { ![regexp ":" $url match] && ![regexp {[?]} $url match] && [string range $url 0 0] != "/" } {
				# it is a relative link I must add auto_cache before
				set result "$local_conf(autocache_dirname)/${url}"
			} else {
				# It is an absolute link
				set result "$url"
			}
			set result "$start$result$end"
			# fas_debug "$result avec url = $url"
		} else {
			# no url found in the matched tag
			# we return str without changes
			set result "$str"
		}
		return $result
	}
	
	# Procedure for filetypes where there are no automatic conversion
	# Then an "autocache" file may exists. It is xxxx.ext.html . I
	# take it if necessary. If it does not exist I send back an error
	# args should be either pdf or txt or html, html being the default
	proc get_sxi_autocache_content { real_filename args } {
		set autocache_target_filetype html
		if { [llength $args] > 0 } {
			set autocache_target_filetype [lindex $args 0]
		}
		set autocache_file [get_sxi_autocache_filename $real_filename $autocache_target_filetype]
		# Even if it does not exist, if it comes to appear, it depends on it
		fas_depend::set_dependency $autocache_file
		fas_debug "fas_basic_proc::get_autocache_content - autocache_file => $autocache_file"
		if { [file readable ${autocache_file}] } {
			set content ""
			# OK I take it

			if { [catch {
				set fid [open ${autocache_file}]
				if { $autocache_target_filetype == "pdf" } {
					fconfigure $fid -encoding binary -translation binary
				}
				set content [read $fid]
				close $fid
			} ] } {
				set content "sxi::get_sxi_autocache_content [translate "Problem while loading autocache file :"] $autocache_file"
			}
		} else {
			set content "sxi::get_sxi_autocache_content [translate "No autocache file defined"] $autocache_file"
		}
		return $content
	}

	# args should be either html pdf or txt
	# The name will be :
	# file = /tmp/ucometest/any/test/test.sxi
	# result = /tmp/ucometest/any/test/autocache/test.sxi/test.sxi.html
	proc get_sxi_autocache_filename { filename args} {
		set extension html
		if { [llength $args] > 0 } {
			set extension [lindex $args 0]
		}
		# I add autocache to the directory name. I could
		# use a hidden directory, but I prefer to keep it
		# like that.
		# I am going to create a specific directory
		set autocache_dir [file join [file dirname $filename] autocache [file tail $filename]]
		
		return [file join $autocache_dir "[file tail ${filename}].${extension}"]
	}

}
