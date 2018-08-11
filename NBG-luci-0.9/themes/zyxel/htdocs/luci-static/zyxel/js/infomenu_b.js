$('div[class^="button"]').hover(function(){
	
	$(this).children('ul').toggleClass('visible');
});
