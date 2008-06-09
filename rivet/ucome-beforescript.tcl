global IN_COMP ERROR_LOOP _cgi_uservar fas_env
set IN_COMP 0
set ERROR_LOOP 0
set errors 0
set errstr ""
array unset _cgi_uservar 
array unset fas_env 

# Now
set test "/any/index.html"
global IN_COMP ERROR_LOOP errors errstr
set IN_COMP 0
set ERROR_LOOP 0
set errors 0
set errstr ""
	
if { [info exists fas_env] } {
	array unset fas_env
}


init_debug
fas_init

# I startup all initialisation procedures
global filetype_list
foreach filetype $filetype_list {
	if { [llength [info command ${filetype}::init]] > 0 }  {
		fas_fastdebug {ucome.tcl::UCome - ${filetype}::init}
		${filetype}::init
	}
}

cgi_input data
