# Enable (0) or Disable debug (0)
set DEBUG 1
# At 0 generate a file in /tmp with all debugging informations.
# Useful on a big crash to determine where fas_view crashes
set DEBUG_FILE 1
# Show debug on html pages
set DEBUG_SHOW 1
# Mandatory - global variables in which all messages are accumulated
set DEBUG_STRING ""
# At 0 every possible message are enabled for all namespace
set DEBUG_ALL 0
# At 0 debug messages of function in no namespace are displayed
set DEBUG_MAIN 1
# Enable debug message for a given namespace
# If a LOCAL_DEBUG_COLOR is defined then messages are in this color
# for this namespace
catch {set atemt::LOCAL_DEBUG 0 }
catch {set fas_depend::LOCAL_DEBUG 0 }
catch {set fas_depend::LOCAL_DEBUG_COLOR "#00FFFF" }
catch {set fas_session::LOCAL_DEBUG 1}
catch {set fas_name_and_dir::LOCAL_DEBUG 0}

catch {set binary::LOCAL_DEBUG 1}
catch {set mpeg::LOCAL_DEBUG 0}
catch {set mp4::LOCAL_DEBUG 0}
catch {set avi::LOCAL_DEBUG 0}
catch {set gif::LOCAL_DEBUG 0}
catch {set png::LOCAL_DEBUG 0}
catch {set jpeg::LOCAL_DEBUG 0}
catch {set tiffg3::LOCAL_DEBUG 0}
catch {set tiffg3::LOCAL_DEBUG_COLOR "#44FF44"}
catch {set swf::LOCAL_DEBUG 1}
catch {set swf::LOCAL_DEBUG_COLOR "#66FF66"}

catch {set not_binary::LOCAL_DEBUG 0}
catch {set rrooll::LOCAL_DEBUG 0}
catch {set txt::LOCAL_DEBUG 0}
catch {set tmpl::LOCAL_DEBUG 1}
catch {set fashtml::LOCAL_DEBUG 0}
catch {set htmf::LOCAL_DEBUG 1}
catch {set order::LOCAL_DEBUG 1}
catch {set other::LOCAL_DEBUG 0}
catch {set pdf::LOCAL_DEBUG 0}
catch {set comp::LOCAL_DEBUG 1}
catch {set comp::LOCAL_DEBUG_COLOR "#00FFFF"}
catch {set domp::LOCAL_DEBUG 1}
catch {set menu::LOCAL_DEBUG 1}
catch {set menu::LOCAL_DEBUG_COLOR "#0000FF"}
catch {set mini_menu::LOCAL_DEBUG 0}
catch {set mini_menu::LOCAL_DEBUG_COLOR "#FFFF00"}
catch {set title::LOCAL_DEBUG 0}

catch {set doc::LOCAL_DEBUG 0}
catch {set todo::LOCAL_DEBUG 0}
catch {set sxw::LOCAL_DEBUG 0}
catch {set sxw::LOCAL_DEBUG_COLOR "#FFFF00"}
catch {set sxc::LOCAL_DEBUG 0}
catch {set sxc::LOCAL_DEBUG_COLOR "#FFFF00"}
catch {set sxi::LOCAL_DEBUG 0}
catch {set sxi::LOCAL_DEBUG_COLOR "#FFFF00"}
catch {set sxd::LOCAL_DEBUG 0}
catch {set sxd::LOCAL_DEBUG_COLOR "#FFFF00"}
catch {set csv::LOCAL_DEBUG 0}
catch {set bus0::LOCAL_DEBUG 0}
catch {set ucome_doc::LOCAL_DEBUG 0}
catch {set xml::LOCAL_DEBUG 0}
catch {set next::LOCAL_DEBUG 0}

catch {set order_dir::LOCAL_DEBUG 0}
catch {set edit_form::LOCAL_DEBUG 0}
catch {set delete_form::LOCAL_DEBUG 0}
catch {set edit::LOCAL_DEBUG 0}
catch {set treedir::LOCAL_DEBUG 0}
catch {set dir::LOCAL_DEBUG 0}
catch {set dir::LOCAL_DEBUG_COLOR "#FF00FF" }
catch {set flatten::LOCAL_DEBUG 0}
catch {set upload::LOCAL_DEBUG 0}
catch {set prop_form::LOCAL_DEBUG 0}
catch {set clean_cache_form::LOCAL_DEBUG 0}
catch {set clean_cache::LOCAL_DEBUG 0}
catch {set create_index::LOCAL_DEBUG 0}
catch {set search::LOCAL_DEBUG 0}
catch {set form::LOCAL_DEBUG 0}
catch {set fas_user::LOCAL_DEBUG 0}
catch {set allow_action_form::LOCAL_DEBUG 0}
catch {set allow_action::LOCAL_DEBUG 0}
catch {set allow_action_final::LOCAL_DEBUG 0}
catch {set show_action_list::LOCAL_DEBUG 0}
catch {set login_form::LOCAL_DEBUG 1}
catch {set login::LOCAL_DEBUG 1}
catch {set txt4index_tree::LOCAL_DEBUG 0}
catch {set txt4index_tree::LOCAL_DEBUG_COLOR "#00FF00"}
catch {set txt4index::LOCAL_DEBUG 0}
catch {set txt4index::LOCAL_DEBUG_COLOR "#44FF44"}
catch {set change_look::LOCAL_DEBUG 0}
catch {set change_look::LOCAL_DEBUG_COLOR "#44FF44"}
catch {set path::LOCAL_DEBUG 0}
catch {set path::LOCAL_DEBUG_COLOR "#44FF44"}
catch {set menu_form::LOCAL_DEBUG 1}
catch {set menu_form::LOCAL_DEBUG_COLOR "00FF00"}
catch {set password::LOCAL_DEBUG 1}
catch {set password::LOCAL_DEBUG_COLOR "00FF00"}
catch {set full_menu::LOCAL_DEBUG 0}
catch {set candidate_order::LOCAL_DEBUG 0}
