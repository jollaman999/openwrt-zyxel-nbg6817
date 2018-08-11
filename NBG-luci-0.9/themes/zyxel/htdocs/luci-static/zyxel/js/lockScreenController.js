function skm_unLockScreen(){
		var load = document.getElementById("load");
         var lock = document.getElementById("skm_LockPane");
		 var lock_left = window.parent.menu.document.getElementById("skm_LockPane");
		 var lock_right = window.parent.easy.document.getElementById("skm_LockPane");
		 var lock_top = window.parent.parent.topFrame.document.getElementById("skm_LockPane");
		 var lock_bottom = window.parent.parent.bottom.document.getElementById("skm_LockPane");
		 document.getElementsByTagName("body")[0].style.overflow = "auto";
		 
         if (lock) 
            lock.className = 'LockOff'; 
			load.className = 'LockOff'; 
	     if (lock_left) 
            lock_left.className = 'LockOff'; 
			
		 if (lock_right) 
            lock_right.className = 'LockOff'; 		
		
		if (lock_top) 
            lock_top.className = 'LockOff'; 	
			
		if (lock_bottom) 
            lock_bottom.className = 'LockOff'; 	

}



function skm_LockScreen(){ 


		var load = document.getElementById("load");
         var lock = document.getElementById("skm_LockPane");
		 var lock_left = window.parent.menu.document.getElementById("skm_LockPane");
		 var lock_right = window.parent.easy.document.getElementById("skm_LockPane");
		 var lock_top = window.parent.parent.topFrame.document.getElementById("skm_LockPane");
		 var lock_bottom = window.parent.parent.bottom.document.getElementById("skm_LockPane");
		 document.getElementsByTagName("body")[0].style.overflow = "hidden";
		 
         if (lock) 
            lock.className = 'LockOn'; 
			load.className = 'spinner'; 
	     if (lock_left) 
            lock_left.className = 'LockOn'; 
			
		 if (lock_right) 
            lock_right.className = 'LockOn'; 		
		
		if (lock_top) 
            lock_top.className = 'LockOn'; 	
			
		if (lock_bottom) 
            lock_bottom.className = 'LockOn'; 	
			
       
      } 


$(document).ready(function() {

	// append lock div at end of body.
    $(document.body).append('<div id="load" class="LockOff"> <div class="spinner-container container1"> <div class="circle1"></div> <div class="circle2"></div> <div class="circle3"></div> <div class="circle4"></div> </div> <div class="spinner-container container2"> <div class="circle1"></div> <div class="circle2"></div> <div class="circle3"></div> <div class="circle4"></div> </div> <div class="spinner-container container3"> <div class="circle1"></div> <div class="circle2"></div> <div class="circle3"></div> <div class="circle4"></div> </div> </div> <div id="skm_LockPane" class="LockOff"></div>'); 

    // Perform unlock on body load to reset locking status.
    $(document.body).attr('onload', function(){
    	skm_unLockScreen();
    });

});
