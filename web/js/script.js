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
                   var li = "<li>";;
                   li += '<img src="' + val['avatar'] + '">';
                   li += '<span class="notification">' + val['status'] + '</span>';
                   li += '<a>Add</a>';
                   li += '<a>Play</a>';
                   li += "</li>";
                   $('#activity .table-view').append(li)
            });
  });               
});