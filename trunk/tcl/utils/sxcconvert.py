#!/usr/local/OpenOffice.org1.1.0/program/python

# Use example :
# /usr/local/OpenOffice.org1.1.0/program/python ./ooconvert.py --pdf /home/ludo/doc/fete_ecole2003.sxw /tmp/test.pdf
import os, sys, getopt
#sys.path.insert(0 , '/usr/local/OpenOffice.org1.1.0/program')
#sys.path.insert(0 , '/usr/local/OpenOffice.org1.1.0/program/python-core/lib')
#sys.path.insert(0 , '/usr/local/OpenOffice.org1.1.0/program/python-core/lib/lib-dynload')
#os.putenv('LD_LIBRARY_PATH', '/usr/local/OpenOffice.org1.1.0/program')

import uno
from unohelper import Base,systemPathToFileUrl, absolutize

from com.sun.star.beans import PropertyValue
from com.sun.star.beans.PropertyState import DIRECT_VALUE
from com.sun.star.uno import Exception as UnoException
from com.sun.star.io import IOException,XInputStream, XOutputStream


opts, args = getopt.getopt(sys.argv[1:], "hc:",["help", "connection-string=" , "html", "pdf"])
format = None
url = "uno:socket,host=localhost,port=2002;urp;StarOffice.ComponentContext"
filterName = "Text - txt - csv (StarCalc)"
for o, a in opts:
    if o in ("-h", "--help"):
    	print "ooconvert [--pdf] [--html] source target"
    	print "By default, convert to text."
    	print "Input document must be MS EXCEL or OO SXC"
        sys.exit()
    if o in ("-c", "--connection-string" ):
        url = "uno:" + a + ";urp;StarOffice.ComponentContext"
    if o == "--html":
        filterName = "HTML (StarCalc)"
    if o == "--pdf":
        filterName = "calc_pdf_Export"

if len(sys.argv) < 3:
    sys.exit(1)

# get the uno component context from the PyUNO runtime
localContext = uno.getComponentContext()

# create the UnoUrlResolver 
resolver = localContext.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", localContext )
# connect to the running office 				
ctx = resolver.resolve( url )
smgr = ctx.ServiceManager

desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx )

# open input file
inProps = PropertyValue( "Hidden" , 0 , True, 0 ),
fileUrl = systemPathToFileUrl(args[0])
if fileUrl[0:5] != 'file:':
    fileUrl = uno.absolutize( os.getcwd(), systemPathToFileUrl( args[0]) )

doc = desktop.loadComponentFromURL( fileUrl , "_blank", 0,inProps)
if doc == None:
    sys.stderr.write( "Can't open input file " + fileUrl + "\n")
    sys.exit(1)

# Convert and output
outProps = PropertyValue( "FilterName" , 0, filterName , 0 ),
fileUrl = systemPathToFileUrl(args[1])
if fileUrl[0:5] != 'file:':
    fileUrl = uno.absolutize( os.getcwd(), systemPathToFileUrl( args[1]) )

try:
    doc.storeToURL(fileUrl, outProps)
except IOException, e:
    sys.stderr.write( "Error during conversion: " + e.Message + "\n" ) 

doc.dispose()

sys.exit(0)



