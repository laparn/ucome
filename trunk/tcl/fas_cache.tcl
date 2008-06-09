# fas_cache.tcl
# cache management
namespace eval fas_cache {
    proc get_file_or_cache { current_env filetype filename } {
        fas_debug "fas_cache::get_file_or_cache - Entering"
        upvar $current_env fas_env
        set real_filename [fas_name_and_dir::get_real_filename $filetype $filename fas_env]

        # Basically, the output depends on the input file
        fas_depend::set_dependency $real_filename file

        # Now I read the file
        set fid [open $real_filename]
        set content [read $fid]
        close $fid
        return $content
    }
}