/* script.js */

function revealFromTop(target) {
	$(target).animate({
		top:'0'
	}, 200);
}

function hideFromTop(target) {
	$(target).animate({
		opacity:0,
		top:'-100%'
	}, 200);
}

$(document).ready(function () {
  $.getJSON('http://spunapi.herokuapp.com/feed.json', function(data) {
            var items = [];
            $.each(data, function(key, val) {
                   $.each(val, function(key, val) {
                          alert(key + val);
                   });
            });
  });               
});