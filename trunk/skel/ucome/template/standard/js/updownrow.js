Node.prototype.swapNode = function (node) {
    var nextSibling = this.nextSibling;
    var parentNode = this.parentNode;
    node.parentNode.replaceChild(this, node);
    parentNode.insertBefore(node, nextSibling);
}

function D_swapNode(n1,n2) {
	if (n1 != null && n2 != null) {
		tempObjB = n2.cloneNode(true);
		tempObjA = n1.cloneNode(true);
	
		n2.parentNode.insertBefore(tempObjA,n2);
		n1.parentNode.insertBefore(tempObjB,n1);
	
		n1.parentNode.removeChild(n1);
		n2.parentNode.removeChild(n2);
		
		return tempObjA;
	}
}

function change_all_counters() {
	//debug('change_all_counters entering');
	var t=document.getElementById('table0');
	var current_rows = t.rows;
	var l = current_rows.length;
	for (i=1; i<l; i++) {
		// debug(current_rows[i].id);
		for (j=0; j<l-1; j++) {
			if ( current_rows[i].id == ('tr'+j)) {
				current_counter=document.getElementById('order.counter.'+j);
				current_counter.value=i-1;
			}
		}
	}
}
	

function find_row(nber) {
	//debug('find_row:: looking for '+nber);
	var t=document.getElementById('table0');
	var current_rows = t.rows;
	var l = current_rows.length;
	for (i=0; i<l; i++) {
		// debug(current_rows[i].id);
		if ( current_rows[i].id == ('tr'+nber)) {
			return(i);
		}
	}
	return(-1);
}
	
function up(current_row_nber) {
	//debug('up('+current_row_nber+')');
	// So I know the current row.
	// I need to now what will be the other row.
	// So what is the physical position of this row ?
	var real_nber=find_row(current_row_nber);
	var second_physical_position = -1;
	//debug('Physical position of tr'+current_row_nber+' is '+real_nber);
	if ( real_nber == 1 ) {
		var l = document.getElementById('table0').rows.length;
		// beware, we speak of 2 different numbers
		// current_row_nber is the id table0_rowX
		// while the second argument, is the position
		// in the different rows
		second_physical_position=l-1;
	} else {
		second_physical_position=real_nber-1;
	}
	//debug('The row above is  at position '+second_physical_position);
	var current_table = document.getElementById('table0');
	info('Swapping physical positions '+real_nber+' with '+second_physical_position);
	current_row_one = current_table.rows[real_nber];
	current_row_two = current_table.rows[second_physical_position];
	D_swapNode(current_row_one,current_row_two);
	change_all_counters();
}

function down(current_row_nber) {
	//debug('down('+current_row_nber+')');
	// So I know the current row.
	// I need to now what will be the other row.
	// So what is the physical position of this row ?
	var real_nber=find_row(current_row_nber);
	var second_physical_position = -1;
	var r = document.getElementById('table0').rows;
	//debug('Physical position of tr'+current_row_nber+' is '+real_nber);
	if ( real_nber == (r.length - 1) ) {
		// beware, we speak of 2 different numbers
		// current_row_nber is the id table0_rowX
		// while the second argument, is the position
		// in the different rows
		second_physical_position=1;
	} else {
		second_physical_position=real_nber+1;
	}
	//debug('The row below is at position '+second_physical_position);
	var current_table = document.getElementById('table0');
	info('Swapping physical positions '+real_nber+' with '+second_physical_position);
	current_row_one = current_table.rows[real_nber];
	current_row_two = current_table.rows[second_physical_position];
	D_swapNode(current_row_one,current_row_two);
	change_all_counters();
}
