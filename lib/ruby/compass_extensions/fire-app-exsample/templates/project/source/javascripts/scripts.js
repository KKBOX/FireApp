$(document).ready(function () {
	$('.nav *').bind('click', function (e) {
		e.preventDefault();
	});
	/*
	$('.sidebar-nav li').hide();
	$('.sidebar-nav .nav-header').show().css({'cursor':'pointer'});
	$('.sidebar-nav .nav-header').bind('click', function (e) {
		// e.preventDefault();
		$(this).parent().find('li').toggle();
		$(this).show();
	});
	*
	$('.searchbox').bind('focus keyup blur', function () {
		if ($(this).val().length > 0) {
			$(this).next('.clear').fadeIn();//.css({'display':'inline-block'});
		} else {
			$(this).next('.clear').fadeOut();//.css({'display':'none'});
		}
	});
	$('.clear').bind('click', function () {
		$(this).prev('.searchbox').val('').focus();
		$(this).fadeOut();//.css({'display':'none'});
	})
	
	$(window).resize(function () {
		document.title = $(window).width() +'x'+$(window).height() +' / '+$(document).width() +'x'+$(document).height();
	})

});