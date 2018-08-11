
(function($) {
$.fn.lavaLamp = function(o) {
    o = $.extend({ fx: "linear", speed: 500, click: function(){} }, o || {});

    return this.each(function() {
        var me = $(this), noop = function(){},
            $back = $('<li class="back"><div class="left"></div></li>').appendTo(me),
            $li = $("li", this), curr = $("li.current", this)[0] || $($li[0]).addClass("current")[0];
/*
        $li.not(".back").hover(function() {
            move(this);
        }, noop);

        $(this).hover(noop, function() {
            move(curr);
        });
*/
        $li.click(function(e) {
            setCurr(this);
            return o.click.apply(this, [e, this]);
        });

        setCurr(curr);

        function setCurr(el) {
            $back.css({ "left": el.offsetLeft+"px", "width": el.offsetWidth+"px" });
            curr = el;
        };

        function move(el) {
            $back.each(function() {
                $(this).dequeue(); }
            ).animate({
                width: el.offsetWidth,
                left: el.offsetLeft
            }, o.speed, o.fx);
        };

    });
};
})(jQuery);
