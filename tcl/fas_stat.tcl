namespace eval fas_stat {

	proc init { } {
	}

	proc append_stat { } {
		global _cgi_uservar
		set stat_filename [add_root "/stat/log.csv"]
		set date [clock format [clock seconds] -format "%Y/%m/%d:%H:%M:%S" ]
		if { [catch { set filename $_cgi_uservar(file) } ] } {
			# default value
		        set filename /any
		}
		if { [catch { set action $_cgi_uservar(action) } ] } {
		        set action view
		}
		set name [fas_user::who_am_i]
		set ip ""
		global conf
		if { [info exists conf(tclrivet)] } {
			set ip [env REMOTE_ADDR]
		} elseif { [info exists conf(tclhttpd) ] } {
		} else {
			global env
			if { [info exists env(REMOTE_ADDR)] } {
				set ip $env(REMOTE_ADDR)
			}
		}
		if { ![catch {open $stat_filename "a"} fid] } {
			puts $fid "${date};${filename};${action};${name};${ip}"
			close $fid
		}
	}
}
			

