set _(open_IMG) "<BR>\n<CENTER><IMG SRC=\""
set _(close_IMG) "\"></CENTER><BR>"
set _(open_A) "<A"
set _(close_A) "</A>"
# table tags
set _(open_TABLE) "\n<TABLE CELLPADDING=\"3\" BGCOLOR=\"F8F1EB\">"
set _(close_TABLE) "</TABLE>"
set _(open_TABLE_plus) "\n<TABLE CELLPADDING=\"3\" BGCOLOR=\"F8F1EB\" BORDER="
set _(open_TABLE_plus_close_BORDER) ">"
set _(close_TABLE_plus) "</TABLE>"
set _(open_TD) "<TD valign=\"top\">"
set _(close_TD) "</TD>"
set _(open_TD_plus) "<TD valign=\"top\" COLSPAN="
set _(open_TD_plus_close_COLSPAN) ">"
set _(close_TD_plus) "</TD>"
set _(open_TD_TEXT) ""
set _(close_TD_TEXT) ""
set _(open_TR) "<TR>"
set _(close_TR) "</TR>"

#set _(BREAK) "<BR>"
set _(BREAK) ""
#set _(P) "<P>"
set _(P) ""
#set _(close_P) "</P>"
set _(close_P) "\n<BR>\n"
set _(link_mark) "<A NAME=\""
set _(close_link_mark) "\"></A>"
set _(RULER) "<HR>"
set _(open_UL) "<UL>"
set _(close_UL) "</UL>"
set _(list_item_0) "<LI>"
set _(close_list_item_0) "</LI>"
set _(list_item_1) "<LI>"
set _(close_list_item_1) "</LI>"
set _(list_item_2) "<LI>"
set _(close_list_item_2) "</LI>"
set _(list_item_3) "<LI>"
set _(close_list_item_3) "</LI>"
set _(list_item_4) "<LI>"
set _(close_list_item_4) "</LI>"
set _(list_item_5) "<LI>"
set _(close_list_item_5) "</LI>"

set _(open_PRE) "<TABLE WIDTH=100% BGCOLOR=\"#F8F1EB\"><TR><TD> <PRE>"
set _(close_PRE) "</PRE></TD></TR></TABLE>"

# The document title

set _(open_DOC_TITLE) {
<center><img src="fas:/any/m/conf/lbx-img/logo_linbox_800.png"></center>
<center><table BORDER=0 CELLSPACING=0 CELLPADDING=0 NOSAVE>
  <tr>
    <td bgcolor="#EA4F26" align="center"><font color="#FFFFFF" face="Arial" size="4"><b>&nbsp;&nbsp;
}

set _(close_DOC_TITLE) {
    &nbsp;&nbsp;</b></font>
</td>
</tr>
</table></center>
}

# for titles
set _(open_H1) { <!-- H1 --> <table BORDER=0 CELLSPACING=0 CELLPADDING=0 NOSAVE> <tr>&nbsp;<td bgcolor="#EA4F26"><img SRC="fas:/any/m/conf/lbx-img/G_picto.png" height=30 width=31>&nbsp;</td> <td bgcolor="#EA4F26"><font color="#FFFFFF" face="Arial" size="4">&nbsp;<b> }

set _(close_H1) { &nbsp;</b></font> </td> </tr> </table> <br> <!-- /H1 -->
}

set _(open_H2) { <!-- H2 --> <table BORDER=0 CELLSPACING=0 CELLPADDING=0 NOSAVE > <tr><td>&nbsp;&nbsp;&nbsp;</td> <td bgcolor="#EA4F26"><font color="#FFFFFF" face="Arial" size="4"><b>&nbsp; }

set _(close_H2) { &nbsp;</b></font></td></tr> </table> <br> <!-- /H2 --> 
}

set _(open_H3) { <!-- H3 --> <table BORDER=0 CELLSPACING=0 CELLPADDING=0 NOSAVE > <tr> <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>  <td bgcolor="#EA4F26"><font color="#FFFFFF" face="Arial" size="4"><b>&nbsp;
 }

set _(close_H3) { &nbsp;</b></font> </td> </tr> </table> <br> <!-- /H3 -->
}

set _(open_H4) "<!-- H4 --><H4>"
set _(close_H4) "</H4><!-- /H4 -->"
set _(open_H5) "<!-- H5 --><H5>"
set _(close_H5) "</H5><!-- /H5 -->"
set _(open_H6) "<!-- H6 --><H6>"
set _(close_H6) "</H6><!-- /H6 -->"
set _(open_S1) "<B>&nbsp;"
set _(close_S1) "</B><BR>"
set _(open_S2) "&nbsp;&nbsp;&nbsp;"
set _(close_S2) "<BR>"
set _(open_S3) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S3) "<BR>"
set _(open_S4) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S4) "<BR>"
set _(open_S5) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S5) "<BR>"
set _(open_S6) "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
set _(close_S6) "<BR>"
set _(PRINT_H1_NB) "YES"
set _(PRINT_H2_NB) "YES"
set _(PRINT_H3_NB) "YES"
set _(PRINT_H4_NB) "YES"
set _(PRINT_H5_NB) "YES"
set _(PRINT_H6_NB) "YES"
  
# for picture lines (picture alone in the line)
set _(pre_IMG) "<CENTER>"
set _(post_IMG) "</CENTER>"
# for figure lines
set _(pre_FIG) "<BR>\n<CENTER><I>"
set _(post_FIG) "</I></CENTER>"
# for contents
set _(open_CONTENTS) "<I>"
set _(close_CONTENTS) "</I>"
set _(open_A_CONTENTS) "\n<!--A HREF=\""
set _(end_open_A_CONTENTS) "\"-->\n"
set _(close_A_CONTENTS) "\n<!--/A-->\n"
#set _(open_A_CONTENTS) "<A"
#set _(close_A_CONTENTS) "</A>"

# begin-end of web page
set _(open_HTML) "<HTML>"
set _(close_HTML) "</HTML>"
set _(open_BODY) "<BODY"  
set _(close_open_BODY) ">"
set _(close_BODY) {
</BODY>
}
set _(open_HEAD) "<HEAD>
<meta http-equiv=\"content-type\" content=\"text/html; charset=ISO-8859-1\">
<meta http-equiv=\"content-language\" content=\"fr\">
<meta http-equiv=\"pragma\" content=\"no-cache\">
<meta http-equiv=\"cache-control\" content=\"no-cache\">
<META NAME=\"generator\" CONTENT=\"txt2ml v$version\">
<meta http-equiv=\"expires\" content=\"0\">
<meta name=\"author\" content=\"Arnaud LAPREVOTE\">
<meta name=\"description\" content=\"Free&ALter Soft\">
<meta name=\"subject\" content=\"Free&ALter Soft\">
<meta name=\"identifier-URL\" content=\"http://www.freealter.com\">
<meta name=\"keywords\" content=\"free\">
<meta name=\"language\" content=\"fr\">
<meta name=\"revisit-after\" content=\"14 days\">
<meta name=\"robots\" content=\"index, follow\">
"
set _(close_HEAD) "</HEAD>"
set _(open_TITLE) "<TITLE>"
set _(close_TITLE) {
</TITLE> } 
