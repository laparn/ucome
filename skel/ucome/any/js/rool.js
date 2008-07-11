xInclude('fas:/any/js/x_core.js', 'fas:/any/js/x_slide.js', 'fas:/any/js/x_popup.js', 'fas:/any/js/x_timer.js');
var ori_x;
var top;
var bottom;
var i=0;
var winlen;
var doclen;

function scroll(start_delay, end_delay, scroll_delay) {
	if (xIE4Up) {
		if ( i <= 0 ) {
			winlen=document.body.clientHeight;
			doclen=document.body.scrollHeight;
			yd = doclen - winlen;
			yinc = 1;
			i = 1;
			setTimeout("scroll("+start_delay+","+end_delay+","+scroll_delay+")",start_delay);
		} else if (i == 9999) {
			//alert("IE reloads the page...");
			window.location.href=parent.parent.location.href;
			document.body.scrollTop=0;
		} else if (i >= (yd+50)) {
			i = 9999;
			setTimeout("scroll("+start_delay+","+end_delay+","+scroll_delay+")",end_delay);
		} else {
			document.body.scrollTop = i;
			i += yinc;    
			setTimeout("scroll("+start_delay+","+end_delay+","+scroll_delay+")",scroll_delay);
		}
	} else {
		if (i<=0) {
			doclen = document.body.scrollHeight-window.innerHeight;
			yd=doclen;
			yinc = 1;
			i = 1;
                        document.body.scrollTop=0;
			scrollTo(0,0);
			//alert("i="+i+"; start_delay="+start_delay+"; end_delay="+end_delay+";scroll_delay="+scroll_delay);
			setTimeout("scroll("+start_delay+","+end_delay+","+scroll_delay+")",start_delay);
		} else if (i == 9999) {
			//alert("Reloading the page...");
			parent.parent.document.location.href=parent.parent.document.location.href; 
		} else if (i >= (yd+50)) {
			i = 9999;
			setTimeout("scroll("+start_delay+","+end_delay+","+scroll_delay+")",end_delay);
		} else {
			doclen = document.body.scrollHeight-window.innerHeight;
			yd=doclen;
			scrollBy(0,yinc);
			//scrollTo(0,i);
                        //document.body.scrollTop = i;
			i += yinc;
			setTimeout("scroll("+start_delay+","+end_delay+","+scroll_delay+")",scroll_delay);
			//content.innerHTML += i+" - ";
		}
	}
}

function down(section_name, start_delay, slide_time) {

	var section_down=xGetElementById(section_name);
	
	xHide(section_down);
	var x = xPageX(section_down);
	var y = xPageY(section_down);
	var slide = slide_time;
	xMoveTo(section_down, x, -2000);
	setTimeout("xShow(xGetElementById('"+section_name+"'));xSlideTo(xGetElementById('"+section_name+"'),"+x+","+y+","+slide+")", start_delay);
}

function up(section_name, start_delay, slide_time) {

	var section_up=xGetElementById(section_name);
	
	xHide(section_up);
	var x = xPageX(section_up);
	var y = xPageY(section_up);
	var slide = slide_time;
	xMoveTo(section_up, x, 2000);
	setTimeout("xShow(xGetElementById('"+section_name+"'));xSlideTo(xGetElementById('"+section_name+"'),"+x+","+y+","+slide+")", start_delay);
}

function left(section_name, start_delay, slide_time) {

	var section_left=xGetElementById(section_name);
	
	xHide(section_left);
	var x = xPageX(section_left);
	var y = xPageY(section_left);
	var slide = slide_time;
	xMoveTo(section_left, -2000, y);
	setTimeout("xShow(xGetElementById('"+section_name+"'));xSlideTo(xGetElementById('"+section_name+"'),"+x+","+y+","+slide+")", start_delay);
}

function right(section_name, start_delay, slide_time) {

	section_right=xGetElementById(section_name);
	
	xHide(section_right);
	var x = xPageX(section_right);
	var y = xPageY(section_right);
	var slide = slide_time;
	xMoveTo(section_right, 2000, y);
	setTimeout("xShow(xGetElementById('"+section_name+"'));xSlideTo(xGetElementById('"+section_name+"'),"+x+","+y+","+slide+")", start_delay);
}

function appear(section_name, start_delay, slide_time) {
	var state = start_delay;
	xColor(xGetElementById(section_name),"#FFFFFF");
	setTimeout("xShow(xGetElementById('"+section_name+"'))", state);
	state = state + slide_time /7
	setTimeout("xShow(xGetElementById('"+section_name+"'))",state);
	state = state + slide_time /7;
	setTimeout("xColor(xGetElementById('"+section_name+"'),'#e7e2dd')",state);
	state = state + slide_time /7;
	setTimeout("xColor(xGetElementById('"+section_name+"'),'#cFc5bb')",state);
	state = state + slide_time /7;
	setTimeout("xColor(xGetElementById('"+section_name+"'),'#b7a899')",state);
	state = state + slide_time /7;
	setTimeout("xColor(xGetElementById('"+section_name+"'),'#9f8b77')",state);
	state = state + slide_time /7;
	setTimeout("xColor(xGetElementById('"+section_name+"'),'#876e55')",state);
	state = state + slide_time /7;
	setTimeout("xColor(xGetElementById('"+section_name+"'),'#6e5000')",state);
	state = state + slide_time /7;
}

function trouve_signe() {

	var texte = xGetElementById("signe").innerHTML;
	var signe = texte.substring(0, texte.indexOf("<img", 0));
	var newtexte = texte.substring(0, texte.indexOf("src=", 0)+5);
	newtexte = newtexte + "/ucome.rvt?file=/template/rool/signes/" + signe.toLowerCase() + ".png" + texte.substring(texte.indexOf("#", 5)+1, texte.length);

	xGetElementById("signe").innerHTML = newtexte;

	newtexte="";
	signe="";
	texte="";

	return newtexte;
}
