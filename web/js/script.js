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
                   }, function() { } );
            }
    );
}

function getWeather() {
  
}
/*
  Load the initial page on app launch
*/

function pushToProfile(userID) {
  $('.user-info .user-name').replaceWith('<span class="user-name"></span>');
  $('.user-info .location').replaceWith('<span class="location"></span>');
  
  TouchyJS.Nav.goTo('profile');
  $.getJSON('http://spunapi.herokuapp.com/users/'+userID, function(data) {
            name = data['name'];
            avatar = data['avatar']
            genre = data['genre']
            weather = data['weather']
            status = data['status']
            $('.avatar-img img').attr('src',avatar); 
            $('.user-info .user-name').replaceWith('<span class="user-name">'+name+'</span>');
            $('.user-info .location').replaceWith('<span class="location">'+weather+'</span>');
  });
  
  $.getJSON('http://spunapi.herokuapp.com/users/'+userID+'/badges', function(data) {
            $.each(data, function(key, val) {
                   alert(val['name']+val['image']);
                   });
  });
  
  $.getJSON('http://spunapi.herokuapp.com/users/'+userID+'/songs', function(data) {
            $.each(data, function(key, val) {
                   alert(val['name']);
                   });
            });
  
}

$(document).ready(function () {
  $.getJSON('http://spunapi.herokuapp.com/feed.json', function(data) {
            var items = [];
            $.each(data, function(key, val) {                  
                   var li = "<li>";;
                   li += '<a class="thumbnail" href="#" onclick="pushToProfile(' +val['id']+ ');"><img src="' + val['avatar'] + '"></a>';
                   li += '<span class="notification">' + val['status'] + '</span>';
                   li += '<a class="add-button">Add</a>';
                   li += '<a class="play-button">Play</a>';
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


function activateTab(target){

	var targetParent = $(target).parent();
	var indexNum = $(target).index();
	targetParent.children('.tab-view-buttons').children('a').removeClass('active');
	targetParent.children('.tab-view-buttons').children('a:nth-child('+indexNum+')').addClass('active');
	
	targetParent.children('.tab').removeClass('active');
	$(target).addClass('active');
	
	
}
function updateLocation(position) {
  alert(position.coords.latitude + " " + position.coords.longitude);
}

function didSubmitSearch(search_form) {
  search_form.term.blur();
  bridge(search_form);
}

function didFetchPlaylists(spotify_playlists) {
  var did_populate_first_song = false;
  $("#player-form").submit(function() {
    bridge(this);
    postPlayedSong($("#player-form input[name='track']").val());
    return false;
  });
  $.each(spotify_playlists, function(playlist, value) {
    $(value).each(function(index, track) {
      if (!did_populate_first_song) {
        did_populate_first_song = true;
        populatePlayerForm(playlist, track);
        $("#player-form input[type='submit']").click();
      }
    });
  });
}

function populatePlayerForm(playlist, track) {
  $("#player-form #song-title").text(track);
  $("#player-form #song-playlist").text(playlist);
  $("#player-form input[name='track']").val(track);
  $("#player-form input[name='playlist']").val(playlist);
}

function bridge(form) {
  window.location = form.action + $(form).serialize();
}
