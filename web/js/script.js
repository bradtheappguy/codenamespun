/* script.js */

var global_playlists = null;
var search_callback = null;

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

$(function() {
	 $('.tab-navigator a').click(function(){
		$('.tab-navigator a').removeClass('active');
		$(this).addClass('active');
	 });
});

function didSubmitSearch(search_form) {
  search_form.term.blur();
  bridge(search_form);
}

function didFetchPlaylists(itunes_playlists, spotify_playlists) {
  itunes_playlists.each(function(playlist) {
    alert(playlist.name);
  });

  spotify_playlists.each(function(playlist) {
    alert(playlist.name);
  });
}

function didFetchSearchResults(songs) {
  if (search_callback) {
    search_callback(songs);
  }
}

function bridge(form) {
  iframe = document.createElement("IFRAME");
  iframe.setAttribute("src", form.action + $(form).serialize());
  document.body.appendChild(iframe); 
  iframe.parentNode.removeChild(iframe);
  iframe = null;
}
