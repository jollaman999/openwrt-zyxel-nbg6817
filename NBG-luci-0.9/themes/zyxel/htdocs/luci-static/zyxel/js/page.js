$(function(){
	
	var _default = 0, 
		$block = $('#showdevice'), 
		$tabs = $('.tabs'), 
		$tabsLi = $tabs.find('li'), 
		$tab_content = $block.find('.tab_content'), 
		$tab_contentLi = $tab_content.find('.move'), 
		_width = $tab_content.width();
 
	
	$tabsLi.hover(function(){
		var $this = $(this);
		$this.find('a').toggleClass('hover');
		
		if($this.hasClass('active')) return;
		
		$this.toggleClass('hover');
	}).click(function(){	
	
		var $active = $tabsLi.filter('.active').removeClass('active'), 
			_activeIndex = $active.index(),  
			$this = $(this).addClass('active').removeClass('hover'), 
			_index = $this.index(), 
			isNext = _index > _activeIndex;
 
		
		if(_activeIndex == _index) return;
		$tabsLi.find('a').removeClass('active'),
		$this.find('a').toggleClass('active'),
		
		$tab_contentLi.eq(_activeIndex).stop().animate({
			left: isNext ? -_width : _width
		}).end().eq(_index).css('left', isNext ? _width : -_width).stop().animate({
			left: 0
		});
	});
 
	
	$tabsLi.eq(_default).addClass('active');
	$tabsLi.eq(_default).find('a').addClass('active');
	$tab_contentLi.eq(_default).siblings().css({
		left: _width
	});
});