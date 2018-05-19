
(function($) {
	$.fn.slide = function(settings) {
		settings = jQuery.extend({
			firstload		: 0,
			showmode		: "normal",	// [ random | normal ]
			action			: "auto",	// [ auto | click ]
			interval_mode	: "normal",	// [ random | normal ]
			interval_normal	: 4500,
			interval_min	: 1,
			interval_max	: 1,
			animation		: true,		// [ true | false ]
			fadespeed		: 1000
		}, settings);

		var _root	= this;
		var max		= $(this).find("li").length;
		var current	= settings.firstload;

		$(this).find("li").not(":eq(" + current + ")").hide();

		if(settings.action == "auto") {
			intervalmode_check();
		} else if(settings.action == "click") {
			$(this).click(animation);
		}

		function intervalmode_check() {
			if(settings.interval_mode == "normal") {
				setTimeout(animation, settings.interval_normal);
			} else {
				var time = settings.interval_min + Math.floor(Math.random() * (settings.interval_max + 1));
				setTimeout(animation, time);
			}
		}

		function animation() {
			var prev = $(_root).find("li").eq(current);
			var n = current;
			if(settings.showmode == "normal") {
				if(current == (max- 1)) {
					current = 0;
				} else {
					current++;
				}
			} else {
				current = Math.floor(Math.random() * max);
			}
			var next = $(_root).find("li").eq(current);
			if(n == current) {
				animation();
			} else {
				if(settings.animation == true) {
					prev.fadeOut(settings.fadespeed);
					next.fadeIn(settings.fadespeed);
				} else {
					prev.hide();
					next.show();
				}
				intervalmode_check();
			}
		}
	}
})(jQuery);
