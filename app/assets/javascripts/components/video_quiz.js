function load_component_video_quiz() {
  // does async loading of the youtube script dependency
  function addYouTubeScript() {
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
  }

  // this is called when the youtube script is loaded and prepares our usage of it,
  // searching for video containers and creating the YT players and event handlers
  function onYouTubeIframeAPIReady() {
    // reads time in the form of MM:SS and translates it to plain seconds
    function readTime(sTime) {
      if(sTime === null)
        return 0;
      var parts = sTime.split(":");
      return (((parts[0]|0) * 60) + (parts[1]|0));
    }

    // returns a closure that handles state change events
    // from youtube, e.g. video playing or video paused.
    //
    // Using the closure variables, it can handle multiple independent
    // players, creating a new timer for each of them and calculating
    // when quizzes need to be shown by looking at html attributes.
    function onPlayerStateChange(player, holder) {
      var interval = null;
      var quizzes = {};

      $(".quiz").each(function(idx, quiz) {
        quizzes[readTime(quiz.getAttribute("data-time-to-display"))] = quiz;
      });

      return function(event) {
        // if playing, we set the polling timer to check the time
	// and display stuff needed there. If it is not playing, we
	// stop the timer interval.
        if (event.data == YT.PlayerState.PLAYING) {
          if(interval)
            clearInterval(interval);
          interval = setInterval(function() {
            var time = Math.floor(player.getCurrentTime());
            if(quizzes[time]) {
              player.stopVideo();

              var q = quizzes[time];
              q.style.display = "block";
              $("textarea", q).focus();
              quizzes[time] = null; // so it will not appear again
            }
          }, 500);
        } else {
          if(interval)
            clearInterval(interval);
          interval = null;
          }
      };
    }

    $(".annotated-video").each(function(idx, holder) {
      // 640x390 is the default ratio, so we want to keep to that while making it fit
      // in the actual box we have. So we'll look at the current width and change the
      // height to have that ratio before inserting the video.
      var w = holder.offsetWidth;
      var h = w / 640 * 390;
      holder.style.height = h + "px";

      // we'll automatically add a player-holder to hold the youtube iframe itself
      var playerHolder = document.createElement("div");
      playerHolder.className = "player-holder";
      holder.insertBefore(playerHolder, holder.firstChild);

      var player = new YT.Player(playerHolder), {
        height: holder.height,
        width: holder.width,
        videoId: holder.getAttribute("data-youtube-id"),
        playerVars: {
          'start': readTime(holder.getAttribute("data-start-time")),
	  'playsinline': 1, // keeps it inline even on iOS so we can draw over it
	  'modestbranding': 1, // disables the "watch on youtube" button
	  'fs':0 // disables the full screen button, so we can still pop up over it
        }
      });

      player.addEventListener("onStateChange", onPlayerStateChange(player, holder));

      // This handles the close button inside the quizzes.
      // The quiz html must include the button, but should not include
      // the javascript to resume playing because we do it here.
      $(holder).click(function(event) {
        if(event.target.tagName == "BUTTON") {
          var e = event.target;
          e = e.parentNode;
          e.style.display = 'none';
          player.playVideo();
        }
       });
    });
  }

  // make our handler available for the youtube script to find
  // this name must not change
  window.onYouTubeIframeAPIReady = onYouTubeIframeAPIReady;

  // and asynchronously load the youtube API code
  addYouTubeScript();
}
