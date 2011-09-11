/* script.js */

var global_playlists = null;
var search_callback = null;
var current_playlist = null;
var current_track = null;
var playlists = null;

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
  alert('post played');
  $.getJSON('http://api.wunderground.com/api/d027b704c23bc8ed/geolookup/conditions/conditions/q/autoip.json', function(data) {
            weather = data['current_observation']['weather'];
            temp = data['current_observation']['temp_f'];
            $.post('http://spunapi.herokuapp.com/songs', 
                   { 'song[name]': name, 
                     'song[user_id]': '1',
                     'user[weather]': weather + ' ' + temp
                   }, function() { alert(name); } );
            }
    );
}




function pushToProfile(userID) {
  $('.user-info .user-name').replaceWith('<span class="user-name"></span>');
  $('.user-info .location').replaceWith('<span class="location"></span>');
  
  TouchyJS.Nav.goTo('profile');
  updateProfile(userID);
}

function updateProfile(userID)  {
  $.getJSON('http://spunapi.herokuapp.com/users/'+userID+'.json', function(data) {
            name = data['name'];
            avatar = data['avatar']
            genre = data['genre']
            weather = data['weather']
            status = data['status']
            $('.avatar-img img').attr('src',avatar); 
            $('.user-info .user-name').replaceWith('<span class="user-name">'+name+'</span>');
            $('.user-info .location').replaceWith('<span class="location">'+weather+'</span>');
  });
  
  $.getJSON('http://spunapi.herokuapp.com/users/'+userID+'/badges.json', function(data) {
            $.each(data, function(key, val) {
                   //alert(val['image']);
                   badge = '<div class="user-badge"><img src="'+ val['image'] +'" class="badge-img"/>'+val['name']+'</div>';
                   $('#profile .user-badges').append(badge);
                   });
  });
  

  $.getJSON('http://spunapi.herokuapp.com/users/'+userID+'/songs.json', function(data) {
            $.each(data, function(key, val) {
                   var li = "<li>";
                   //li += '<a class="thumbnail" href="#" onclick="pushToProfile(' +val['id']+ ');"><img src="' +val['avatar'] + '"></a>';
                   li += '<span class="notification">' + val['name'] + '</span>';
                   li += '<a class="add-btn">Add</a>';
                   li += '<a class="play-btn">Play</a>';
                   li += "</li>";
                   $('#profile .activity-feed').append(li);
                   });
                  
            });
  
}

$(document).ready(function () {
  $.getJSON('http://spunapi.herokuapp.com/feed.json', function(data) {
    var items = [];
    $.each(data, function(key, val) {                  
      var li = "<li>";;
      li += '<a class="thumbnail" href="#" onclick="pushToProfile(' +val['id']+ '); activateBackBtn();"><img src="' + val['avatar'] + '"></a>';
      li += '<span class="notification">' + val['status'] + '</span>';
      li += '<a class="add-btn">Add</a>';
      li += '<a class="play-btn">Play</a>';
      li += "</li>";
      $('#activity .table-view').append(li)
    });
  });               
  $('.tab-navigator a').click(function(){
    $('.tab-navigator a').removeClass('active');
    $(this).addClass('active');
  });
  $("#player-form").submit(function() {
    postPlayedSong($("#player-form input[name='track']").val());
    bridge(this);
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

function didFetchPlaylists(spotify_playlists) {
  playlists = playlists_from_spotify;
}

function populatePlayerForm(playlist, track) {
  $("#player-form #song-title").text(track);
  $("#player-form #song-playlist").text(playlist);
  $("#player-form input[name='track']").val(track);
  $("#player-form input[name='playlist']").val(playlist);
  //$("#player-form input[type='submit']").click();
}

function bridge(form) {
  window.location = form.action + $(form).serialize();
}

function activateBackBtn() {
	
	$('.header-back-btn').bind('click', deactivateBackBtn);
	$('.header-back-btn').addClass('active');
}

function deactivateBackBtn() {
	TouchyJS.Nav.goTo('activity');
	$('.header-back-btn').removeClass('active');

}
