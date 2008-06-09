# I create target cgi, tclhttpd, rivet, site
# Where skel directory content will be copied
# WARNING : not slash "/" at the end on DIR
# Sample : INSTALL_DIR=/home/foo/ucometest
#
INSTALL_DIR=/var/lib/ucome
INSTALL_DIR_ADD_SLASHE=$(subst /,\/,$(INSTALL_DIR))

# Directory where ucome was set up (you will find ucome.cgi there)
MANA_BASE=$(shell pwd)

# The directory in which the file fas_display.tcl may be found
FAS_PROG_ROOT=$(MANA_BASE)/tcl

# Where cgi file will be set-up and corresponding url
INSTALL_CGI_DIR=/usr/lib/cgi-bin/ecim
CGI_URL_DIR=/cgi-bin/ecim

# Where TCLHTTPD files are and corresponding url
TCLHTTPD_DIR=$(MANA_BASE)/tclhttpd

# Hostname (for http server) / used in tclhttpd and rivet
HOSTNAME = $(shell hostname)

# String used for generating TCLHTTPD  shell script for starting tclhttpd in init.d
TCLHTTPD_UTIL_STRING=$(subst /,\/,$(MANA_BASE)/tcl/utils/tclhttpd.sh)

# Where custom ucome.tcl script is set up
TCLHTTPD_CUSTOM_DIR=$(subst /,\/,$(MANA_BASE)/tclhttpd/custom)

# Where RIVET files are and corresponding url
RIVET_DIR=/var/www
RIVET_CGI=ucome.rvt
# If you want define RIVET_URL to root dir then set empty value (ex: RIVET_URL=)
RIVET_URL=
RIVET_PROG_ROOT_STRING=$(subst /,\/,$(FAS_PROG_ROOT))
RIVET_ROOT_STRING=$(subst /,\/,$(INSTALL_DIR))

MANA_BASE_ADD_SLASHES=$(subst /,\/,$(MANA_BASE))

WEB_USER=www-data
WEB_GROUP=www-data

site:
	@echo "Installation directory is : $(INSTALL_DIR)"
	@echo "Delete all files in directory : $(INSTALL_DIR) ? (Y/N)"
	@read answer
	@if [[ ("$answer" = "Y") || ("$answer" == "y") ]]; \
	then \
		echo "Deletting all files in $(INSTALL_DIR)..."; \
		-rm -Rf $(INSTALL_DIR); \
	fi
	mkdir -p $(INSTALL_DIR)
	cp -R skel/ucome/* $(INSTALL_DIR)
	mkdir -p $(INSTALL_DIR)/.mana
	cp skel/ucome/.mana/.val $(INSTALL_DIR)/.mana/.val
	chown -R $(WEB_USER):$(WEB_GROUP) $(INSTALL_DIR)

code:
	@echo "Copy all code in any/code"
	-find $(INSTALL_DIR) -name "CVS" -exec rm -R {} \;
	-rm -Rf $(INSTALL_DIR)/any/code
	mkdir -p $(INSTALL_DIR)/any/code/tcl
	cp -R tcl/* $(INSTALL_DIR)/any/code/tcl
	mkdir -p $(INSTALL_DIR)/any/code/cgi-bin
	cp cgi-bin/* $(INSTALL_DIR)/any/code/cgi-bin
	mkdir -p $(INSTALL_DIR)/any/code/rivet
	cp rivet/* $(INSTALL_DIR)/any/code/rivet
	mkdir -p $(INSTALL_DIR)/any/code/.mana
	echo "menu.name \"Source code\" menu.order 5 menu.auto 1 txt4index.ignore 1 linestoshow 10" > $(INSTALL_DIR)/any/code/.mana/.val
	chown -R $(WEB_USER):$(WEB_GROUP) $(INSTALL_DIR)

cgi:
	mkdir -p $(INSTALL_CGI_DIR)
	cp -R $(MANA_BASE)/cgi-bin/ucome.cgi $(INSTALL_CGI_DIR)
	# begin modif Xav
	#cp $(MANA_BASE)/favicon.ico $(INSTALL_CGI_DIR)
	# end modif Xav
	chmod u+rx $(INSTALL_CGI_DIR)/$(FAS_VIEW_FILENAME)
	echo "set ROOT $(INSTALL_DIR)" > $(INSTALL_CGI_DIR)/conf.tcl
	echo "set FAS_PROG_ROOT $(FAS_PROG_ROOT)" >> $(INSTALL_CGI_DIR)/conf.tcl
	echo "set FAS_VIEW_URL $(CGI_URL_DIR)/ucome.cgi" >> $(INSTALL_CGI_DIR)/conf.tcl
	chown -R $(WEB_USER):$(WEB_GROUP) $(INSTALL_CGI_DIR)

tclhttpd:
	sed -e "s/^DAEMON/DAEMON=$(TCLHTTPD_UTIL_STRING)/" $(FAS_PROG_ROOT)/utils/tclhttpd.ori > $(FAS_PROG_ROOT)/utils/tclhttpd
	@echo "#############################################################"
	@echo "USE $(FAS_PROG_ROOT)/utils/tclhttpd as script to put in your init.d"
	@echo "#############################################################"
	echo "set ROOT $(INSTALL_DIR)" > $(MANA_BASE)/tclhttpd/custom/conf.tcl
	echo "set FAS_PROG_ROOT $(FAS_PROG_ROOT)" >>  $(MANA_BASE)/tclhttpd/custom/conf.tcl
	echo "set FAS_VIEW_URL /ucome" >> $(MANA_BASE)/tclhttpd/custom/conf.tcl
	echo "set FAS_VIEW_URL2 \"http://$(HOSTNAME):8017/ucome\"" >> $(MANA_BASE)/tclhttpd/custom/conf.tcl 
	sed -e "s/^set CONFDIR/set CONFDIR $(TCLHTTPD_CUSTOM_DIR)/" $(MANA_BASE)/tclhttpd/custom/ucome.tcl.ori > $(MANA_BASE)/tclhttpd/custom/ucome.tcl
	
	-chown  $(WEB_USER):$(WEB_GROUP) $(MANA_BASE)/tclhttpd/custom/ucome.tcl
	-chown  $(WEB_USER):$(WEB_GROUP) $(MANA_BASE)/tclhttpd/custom/conf.tcl
	chmod u+x $(FAS_PROG_ROOT)/utils/tclhttpd

rivet:
	# begin modif Xav
	#cp $(MANA_BASE)/favicon.ico $(RIVET_DIR)
	# end modif Xav
	sed -e "0,/^set FAS_PROG_ROOT/s//set FAS_PROG_ROOT $(RIVET_PROG_ROOT_STRING)/" $(MANA_BASE)/rivet/ucome-initscript.tcl.ori > $(MANA_BASE)/rivet/ucome-initscript.tcl
	# Modifying ucome.rvt.ori
	sed -e "0,/^set ::ROOT/s//set ::ROOT $(RIVET_ROOT_STRING)/" $(MANA_BASE)/rivet/ucome.rvt.ori > $(MANA_BASE)/rivet/ucome.rvt.1
	sed -e "0,/^set ::FAS_VIEW_CGI/s//set ::FAS_VIEW_CGI $(RIVET_CGI)/" $(MANA_BASE)/rivet/ucome.rvt.1 > $(MANA_BASE)/rivet/ucome.rvt.2
	sed -e "0,/^set FAS_VIEW_URL/s//set FAS_VIEW_URL $(RIVET_URL)\/$(RIVET_CGI)/" $(MANA_BASE)/rivet/ucome.rvt.2 > $(MANA_BASE)/rivet/ucome.rvt.3
	sed -e "0,/^set FAS_HOSTNAME/s//set FAS_HOSTNAME $(HOSTNAME)/" $(MANA_BASE)/rivet/ucome.rvt.3 > $(MANA_BASE)/rivet/ucome.rvt
	rm $(MANA_BASE)/rivet/ucome.rvt.1
	rm $(MANA_BASE)/rivet/ucome.rvt.2
	rm $(MANA_BASE)/rivet/ucome.rvt.3
	cp $(MANA_BASE)/rivet/ucome.rvt $(RIVET_DIR)
	@sed -e "s/MANA_BASE/$(MANA_BASE_ADD_SLASHES)/" rivet_apache.conf.ori > rivet_apache.conf
	@echo "#############################################################"
	@echo "Plase copy rivet_apache.conf to /etc/apache/conf.d/"
	@echo "And check that the rivet extension is properly installed"
	@echo "#############################################################"

clean:
	rm -f tclhttpd/custom/conf.tcl
	rm -f tcl/utils/tclhttpd

doc: site
	@echo "Installation of UCOME documentation"
	mkdir -p $(INSTALL_DIR)
	cp -R skel/doc/* $(INSTALL_DIR)
	chown -R $(WEB_USER):$(WEB_GROUP) $(INSTALL_DIR)

clean_svn:
	@echo "Delete all .svn directory"
	find -name .svn -type d -exec rm -rf {} \;
	
clean_cache:
	rm -rvf $(INSTALL_DIR)/cache/*
	echo "#!/bin/bash" >$(MANA_BASE)/clean.sh
	echo "" >>$(MANA_BASE)/clean.sh
	echo "export MANA_BASE=$(MANA_BASE)" >>$(MANA_BASE)/clean.sh
	cat <$(MANA_BASE)/clean.sh.ori >>$(MANA_BASE)/clean.sh
	chmod u+x $(MANA_BASE)/clean.sh
	$(MANA_BASE)/clean.sh $(INSTALL_DIR)

.PHONY : site tclhttpd cgi rivet ucome clean
