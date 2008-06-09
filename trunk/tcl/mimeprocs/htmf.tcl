#set conf(newtype.htmf) pdf
set conf(extension.htmf) htmf

lappend filetype_list htmf

namespace eval htmf {
	#set local_conf(html.htmldoc) "/usr/bin/htmldoc --webpage -t pdf"
	set local_conf(html.htmldoc) "/usr/bin/htmldoc -t pdf14 --webpage --no-title --linkstyle underline --size A4 --left 1.00in --right 0.50in --top 0.50in --bottom 0.50in --header ... --footer t.1 --tocheader ... --tocfooter t.1 --portrait --color --no-pscommands --compression=1 --jpeg=0 --fontsize 11.0 --fontspacing 1.2 --headingfont Helvetica --bodyfont Helvetica --headfootsize 10.0 --headfootfont Helvetica-Oblique --charset 8859-1 --links --no-truetype --pagemode document --pagelayout single --firstpage p1 --pageeffect none --pageduration 10 --effectduration 1.0 --no-encryption --permissions all --browserwidth 1024"

	global DEBUG_PROCEDURES
	eval $DEBUG_PROCEDURES

	global STANDARD_PROCEDURES
	eval $STANDARD_PROCEDURES

	proc new_type { current_env filename } {
		# When a htmf is met, in what filetype will it be by default
		# translated ?
		#set conf(newtype.txt) htmf
		# This is the default answer
		# in this case I must throw an error
		set result error
		# Now there may be other cases

		if { ![catch { set target [fas_get_value target -noe] } ] } {
			switch -exact -- $target {
				pdf {
					return "pdf"
				}
				# begin modif Xav
				rrooll -
				rool {
					fas_debug_parray fas_env "txt::new_type fas_env before down_stage_env with rool"
					down_stage_env fas_env "rrooll.cgi_uservar."
					fas_debug_parray fas_env "txt::new_type fas_env after down_stage_env with rool"
					return ""
				}
				# end modif Xav
			}
		}
		
		#error 1
		return ""
	}

	# This procedure returns the list of important session variables for
	# this type of file
	proc important_session_keys { } {
		# not any one
		return [list]
	}

	# Return the list of environment variables that are important
	proc env { args } {
		set env_list ""
		lappend env_list [list "pdf.cgi_uservar.txt.perso_tcl" "Tcl file including the html code associated with each \"tag\" of txt and used when transforming the texte file in html for pdf." user]
		lappend env_list [list "pdf.cgi_uservar.txt.style" "File with a css style sheet used in html files obtained after a text transformation before going to pdf." user]
		lappend env_list [list "pdf.cgi_uservar.txt.ginclude_dir" "Directory from which ginclude files are taken from before the pdf transformation." user]
		return $env_list
	}

	proc mimetype { } {
		return "text/html"
	}

	proc ucome_doc { } {
		set content {Directly sent on the output.}
		return $content
	}

	proc 2pdf { current_env filename } {
		upvar $current_env env
		
		set real_filename [fas_name_and_dir::get_real_filename htmf $filename env]	


		# Basically, the output depends on the input file
		fas_depend::set_dependency $filename file
		fas_depend::set_dependency $filename env

		# starting htmldoc
		variable local_conf
		set fid [open "|$local_conf(html.htmldoc) $real_filename"]
		fconfigure $fid -encoding binary -translation binary
		set result [read $fid]
		catch { close $fid }
		#set cache_filename "[cache_filename pdf $filename fas_env]-test"
		#set cache_dirname [file dirname $cache_filename]
		#if { ![file isdirectory $cache_dirname] } {
		#	catch { file mkdir $cache_dirname }
		#}
		#set cache_filename "/tmp/essai1.pdf"
		#catch { eval exec "$local_conf(html.htmldoc) -f $cache_filename $real_filename" }
		#set fid2 [open "/tmp/essai3.pdf" w]
		#fconfigure $fid2 -encoding binary -translation binary
		#puts -nonewline $fid2 $result
		#close $fid2
		return $result
	}

	proc content2pdf { current_env content } {
		upvar $current_env env

		# I must create a random name and store the file there. 
		# I use the same algo than for session. And store in session dir

		set session_name "[clock seconds]_[pid]_[expr int(100000000 * rand())].htmf"
		# I test if it previously exists or not
		#set session_file_name [file join $fas_env(session_dir) $session_name]
		set session_file_name [file join [fas_name_and_dir::get_session_dir] $session_name]
		while { [file readable  $session_file_name ] } {
			set session_name "[clock seconds]_[pid]_[expr int(10000000000 * rand())].htmf"
			#set session_file_name [file join $fas_env(session_dir) $session_name]
			set session_file_name [file join [fas_name_and_dir::get_session_dir] $session_name]
		}
		
		set fid [open $session_file_name w]
		puts $fid $content
		close $fid
		
		# Now converting
		set result [2pdf env $session_file_name]

		# and returning the result
		file delete $session_file_name
		return $result
	}

	proc get_title { filename } {
		set title ""
		if { ![catch {open $filename} fid] } {
			set file [read $fid]
			close $fid
			regexp {< *[Tt][Ii][Tt][Ll][Ee] *>(.*?)< */[Tt][Ii][Tt][Ll][Ee] *>} $file match title
		}
		return $title
	}

	proc 2edit_form { current_env filename } {
		upvar $current_env fas_env
		txt::2edit_form fas_env $filename
	}
	
	proc 2edit { current_env filename } {
		upvar $current_env fas_env
		txt::2edit fas_env $filename
	}

	proc content_display { current_env content } {
		return "[not_binary::content_display_with_session htmf $content]" 
	}

	proc display { current_env filename } {
		upvar $current_env fas_env
		return "[not_binary::display fas_env $filename htmf]"
	}

	proc content { current_env filename } {
		upvar $current_env fas_env
		set tmp_result "[not_binary::content fas_env $filename htmf]"
		return "$tmp_result"
	}
}
