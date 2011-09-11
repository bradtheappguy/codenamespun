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

function postPlayedSong(name) {
  $.getJSON('http://api.wunderground.com/api/d027b704c23bc8ed/geolookup/conditions/conditions/q/autoip.json', function(data) {
            weather = data['current_observation']['weather'];
            temp = data['current_observation']['temp_f'];
            $.post('http://spunapi.herokuapp.com/songs', 
                   { 'song[name]': name, 
                     'song[user_id]': '1',
                     'user[weather]': weather + ' ' + temp
                   });
            }
    );
}

function getWeather() {
  
}
/*
  Load the initial page on app launch
*/
$(document).ready(function () {
                  postPlayedSong('riging hood');
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

function updateLocation(position) {
  alert(position.coords.latitude + " " + position.coords.longitude);
}

function didSubmitSearch(search_form) {
  search_form.term.blur();
  bridge(search_form);
}

function didFetchPlaylists(itunes_playlists, spotify_playlists) {
  $(itunes_playlists).each(function(playlist) {
    alert(playlist.name);
  });

  $(spotify_playlists).each(function(index, name) {
    alert(name);
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
