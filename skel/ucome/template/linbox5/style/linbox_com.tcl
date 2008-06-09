set _(open_IMG) "<div style=\"text-align:center;\"><p><img alt=\"\" src=\""
set _(close_IMG) "\" /></p></div>"
set _(open_A) "<a"
set _(close_A) "</a>"
# table tags
set _(open_TABLE) "\n<table style=\"background-color:#F8F1EB;\">"
set _(close_TABLE) "</table>"
set _(open_TABLE_plus) "\n<table style=\"background-color:#F8F1EB;border:"
set _(open_TABLE_plus_close_BORDER) ";\">"
set _(close_TABLE_plus) "</table>"
set _(open_TD) "<td style=\"\">"
set _(close_TD) "</td>"
set _(open_TD_plus) "<td style=\"\" colspan=\""
set _(open_TD_plus_close_COLSPAN) "\">"
set _(close_TD_plus) "</td>"
set _(open_TD_TEXT) ""
set _(close_TD_TEXT) ""
set _(open_TR) "<tr>"
set _(close_TR) "</tr>"

#set _(BREAK) "<br />"
set _(BREAK) ""
#set _(P) "<p>"
set _(P) ""
#set _(close_P) "</p>"
set _(close_P) "\n<br />\n"
set _(link_mark) "<a title=\""
set _(close_link_mark) "\"></a>"
set _(RULER) "<hr />"
set _(open_UL) "<ul>"
set _(close_UL) "</ul>"
set _(list_item_0) "<li>"
set _(close_list_item_0) "</li>"
set _(list_item_1) "<li>"
set _(close_list_item_1) "</li>"
set _(list_item_2) "<li>"
set _(close_list_item_2) "</li>"
set _(list_item_3) "<li>"
set _(close_list_item_3) "</li>"
set _(list_item_4) "<li>"
set _(close_list_item_4) "</li>"
set _(list_item_5) "<li>"
set _(close_list_item_5) "</li>"

set _(open_PRE) "<pre style=\"background-color:#F8F1EB;\">"
set _(close_PRE) "</pre>"

# The document title

set _(open_DOC_TITLE) { <h1> }
set _(close_DOC_TITLE) { </h1>}

# for titles
set _(open_H1) { <h1> }
set _(close_H1) { </h1> }

set _(open_H2) { <h2> }
set _(close_H2) { </h2> }

set _(open_H3) { <h3> }
set _(close_H3) { </h3> }

set _(open_H4) { <h4> }
set _(close_H4) { </h4> }

set _(open_H5) { <h5> }
set _(close_H5) { </h5> }

set _(open_H6) { <h6> }
set _(close_H6) { </h6> }


set _(open_S1) "<b>&nbsp;"
set _(close_S1) "</b><br />"
set _(open_S2) "&nbsp;&nbsp;&nbsp;"
set _(close_S2) "<br />"
set _(open_S3) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S3) "<br />"
set _(open_S4) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S4) "<br />"
set _(open_S5) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S5) "<br />"
set _(open_S6) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S6) "<br />"

set _(PRINT_H1_NB) "YES"
set _(PRINT_H2_NB) "YES"
set _(PRINT_H3_NB) "YES"
set _(PRINT_H4_NB) "YES"
set _(PRINT_H5_NB) "YES"
set _(PRINT_H6_NB) "YES"
  
# for picture lines (picture alone in the line)
set _(pre_IMG) "<div>"
set _(post_IMG) "</div>"
# for figure lines
set _(pre_FIG) "<br />\n<i>"
set _(post_FIG) "</i>"
# for contents
set _(open_CONTENTS) "<i>"
set _(close_CONTENTS) "</i>"
set _(open_A_CONTENTS) "\n<!--a href=\""
set _(end_open_A_CONTENTS) "\"-->\n"
set _(close_A_CONTENTS) "\n<!--/a-->\n"
#set _(open_A_CONTENTS) "<a"
#set _(close_A_CONTENTS) "</a>"

# begin-end of web page
set _(open_HTML) "<html>"
set _(close_HTML) "</html>"
set _(open_BODY) "<body"  
set _(close_open_BODY) ">"
set _(close_BODY) {
</body>
}
set _(open_HEAD) "<head>
<meta http-equiv=\"content-type\" content=\"text/html; charset=ISO-8859-1\" />
<meta http-equiv=\"content-language\" content=\"fr\" />
<meta http-equiv=\"pragma\" content=\"no-cache\" />
<meta http-equiv=\"cache-control\" content=\"no-cache\" />
<META NAME=\"generator\" CONTENT=\"txt2ml v$version\" />
<meta http-equiv=\"expires\" content=\"0\" />
<meta name=\"author\" content=\"Arnaud LAPREVOTE\" />
<meta name=\"description\" content=\"Free&ALter Soft\" />
<meta name=\"subject\" content=\"Free&ALter Soft\" />
<meta name=\"identifier-URL\" content=\"http://www.freealter.com\" />
<meta name=\"keywords\" content=\"free\" />
<meta name=\"language\" content=\"fr\" />
<meta name=\"revisit-after\" content=\"14 days\" />
<meta name=\"robots\" content=\"index, follow\" />
"
set _(close_HEAD) "</head>"
set _(open_TITLE) "<title>"
set _(close_TITLE) {
</title> } 
