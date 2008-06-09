#!/usr/bin/tclsh8.3
# All functions for flattening an existing site
# I will start from the root directory, and
# create a lololol... with list of files and directories

# Then I will need a function for going threw this list 
# and applying one function or the other.

# A function will be to do a http query on each file having
# a name or being used and the second will be 
# to put all files and figures in a common tree

# I must also change the file name to show that
# they are html files and not txt. The link
# and images must also be updated.
# A link is updated if it starts with http://fsdf/../fas_view.cgi?file=
# the whole think including the root is replaced
# by a given string.

# In simplifying, the flatten operation is just :
#  * regroup html and gif files in the same arborescence
#  * change the name of html files from .xxx into .html
#  * change the link and img using the fas_view.cgi
#    in static links
set not_graphic_list [list .txt .tmpl .html .txt&&& .tmpl&&& .html&&&]
set FAS_PROG_ROOT /home/arnaud/source/mana/tcl

source ${FAS_PROG_ROOT}/fas_debug_procedures.tcl
source ${FAS_PROG_ROOT}/fas_debug.tcl
source ${FAS_PROG_ROOT}/fas_env.tcl

proc copy_graph { root_dir target_dir relative_dir } {
	set final_target_dir [file join $target_dir $relative_dir]
	set ori_dir [file join $root_dir $relative_dir]

	global not_graphic_list 
	puts "copy_graph : $ori_dir"
	set file_list [glob -nocomplain -types {f} -- [file join $ori_dir *]]
	puts "copy_graph found - $file_list"
	foreach file $file_list {
		set file_extension [file extension $file]
		if { [lsearch $not_graphic_list $file_extension] == -1 } {
			# it is a graphic file, I copy it
			puts "copy_graph : copying $file $final_target_dir"
			file mkdir $final_target_dir
			file copy -force $file $final_target_dir
		}
	}
}
	

proc process_dir { root_dir target_dir relative_dir } {
	puts "process_dir - $root_dir $target_dir --> $relative_dir"
	set dir_list [glob -nocomplain -types {d} -- [file join $root_dir $relative_dir *]]
	foreach dir $dir_list {
		if { ![file exists [file join $dir .ignore]] } {
			set relative_dir [string trimleft [string range $dir [string length $root_dir] end] "/"]
			copy_graph $root_dir $target_dir $relative_dir
			process_dir $root_dir $target_dir $relative_dir 
		}
	}
}

proc copy_cache_file { real_root_dir root_dir target_dir target_url relative_dir } {
	global not_graphic_list

	set final_target_dir [file join $target_dir $relative_dir]
	set ori_dir [file join $root_dir $relative_dir]

	set file_list [glob -nocomplain -types {f} -- [file join $ori_dir "*&&&"]]
	puts "copy_cache_file for $ori_dir found - $file_list"
	foreach file $file_list {
		set file_extension [file extension $file]
		# I ignore file with anything else than &&& as a file extension
		puts "copy_cache_file : processing $file - extension is $file_extension"
		set extension_position [lsearch -exact $not_graphic_list $file_extension]
		if { $extension_position == -1 } {
			# It is a graphic file, I do not change it
			set target_file $final_target_dir
		} else {
			# it is a txt or tmpl or html file
			file mkdir $final_target_dir
			set target_file [file join $final_target_dir "[file rootname [file tail $file]].html"]
		}
		file mkdir $final_target_dir
		puts "copy_cache_file $file -> $target_file"
		file copy -force $file $target_file
		# And as I am there, I am also going to clean
		# the file of the false links
		clean_link $real_root_dir $target_url $target_file
	}
}

proc clean_link { root_dir target_url file } {
	puts "clean_link - opening $file"
	if { ![catch {open $file} fid] } {
		set content [read $fid]
		close $fid
		puts "clean_link -- processing $file"
		puts "clean_link regsub -all =\"fas_view.cgi\?   file=$root_dir content $target_url final_content"

		regsub -all "=\"fas_view.cgi\\\?file=${root_dir}(\[^.\]+)\\.txt" $content "=\"${target_url}\\1.html" final_content
		set content $final_content
		regsub -all "=\"fas_view.cgi\\\?file=${root_dir}(\[^.\]+)\\.tmpl" $content "=\"${target_url}\\1.html" final_content
		set content $final_content
		regsub -all "=\"/cgi-bin/mana/fas_view.cgi\\\?file=${root_dir}(\[^.\]+)\\.txt" $content "=\"${target_url}\\1.html" final_content
		set content $final_content
		regsub -all "=\"/cgi-bin/mana/fas_view.cgi\\\?file=${root_dir}(\[^.\]+)\\.tmpl" $content "=\"${target_url}\\1.html" final_content
		set content $final_content
		regsub -all "=\"fas_view.cgi\\\?file=${root_dir}" $content "=\"${target_url}" final_content
		set content $final_content
		regsub -all "=\"/cgi-bin/mana/fas_view.cgi\\\?file=${root_dir}" $content "=\"${target_url}" final_content
		if { ![catch {open $file w} fid] } {
			puts $fid $final_content
			close $fid
		}
	}
}
			
		
proc process_cache_dir { real_root_dir root_dir target_dir target_url relative_dir } {
	puts "process_cache_dir - $root_dir $target_dir --> $relative_dir"
	# First processing the file of the directory
	copy_cache_file $real_root_dir $root_dir $target_dir $target_url $relative_dir
	set dir_list [glob -nocomplain -types {d} -- [file join $root_dir $relative_dir *]]
	puts "process_cache_dir - found following dirs : $dir_list"
	foreach dir $dir_list {
		if { ![file exists [file join $dir .ignore]] } {
			set relative_dir [string trimleft [string range $dir [string length $root_dir] end] "/"]
			# copy_cache_file $real_root_dir $root_dir $target_dir $target_url $relative_dir
			process_cache_dir $real_root_dir $root_dir $target_dir $target_url $relative_dir 
		}
	}
} 
		

set ROOT_DIRECTORY "/home/httpd/html"	
set ROOT "/home/httpd/html/fas_view/any"
set ROOT_URL "/fas_view/any"
set TARGET "/home/httpd/html/fas_site"
set TARGET_URL "/fas_site"
#set ROOT "/home/httpd/html/fas_view/any"
#set TARGET "/home/httpd/html/fr"

read_full_env $ROOT conf
if { [info exists conf(cache.htmf)] } {
	set HTML_CACHE [file join $ROOT_DIRECTORY $conf(cache.htmf)]
} else {
	set HTML_CACHE "${ROOT_DIRECTORY}$conf(cache)/htmf"
}
puts "HTML_CACHE -> $HTML_CACHE"
# First copying the gif files
#process_dir $ROOT $TARGET ""

# Now taking the file of the cache and copying them
process_cache_dir $ROOT_URL $HTML_CACHE $TARGET "$TARGET_URL" ""	
#process_cache_dir $ROOT $HTML_CACHE $TARGET "/fr" ""	
