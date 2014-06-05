function load_youtube_features() {
  function addYouTubeScript() {
    // does async loading of the youtube script dependency
    var tag = document.createElement('script');
    tag.src = "https://www.youtube.com/iframe_api";
    var firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
  }

  // this is called when the youtube script is loaded and prepares our usage of it
  // (the name must not be changed btw)
  function onYouTubeIframeAPIReady() {
    function readTime(sTime) {
      if(sTime === null)
        return 0;
      var parts = sTime.split(":");
      return (((parts[0]|0) * 60) + (parts[1]|0));
    }

    function onPlayerStateChange(player, holder) {
      var interval = null;
      var quizzes = {};

      var qe = holder.querySelectorAll(".quiz");
      for(var a = 0; a < qe.length; a++) {
        var quiz = qe[a];
        quizzes[readTime(quiz.getAttribute("data-time-to-display"))] = quiz;
      }

      return function(event) {
        if (event.data == YT.PlayerState.PLAYING) {
          if(interval)
            clearInterval(interval);
          interval = setInterval(function() {
            var time = Math.floor(player.getCurrentTime());
            if(quizzes[time]) {
              player.stopVideo();

              var q = quizzes[time];
              q.style.display = "block";
              q.getElementsByTagName("textarea")[0].focus();
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

    var list = document.querySelectorAll(".annotated-video");
    for(var a = 0; a < list.length; a++) {
      var holder = list[0];
      var player = new YT.Player(holder.querySelector('.player-holder'), {
        height: holder.height,
        width: holder.width,
        videoId: holder.getAttribute("data-youtube-id"),
        playerVars: {
          'start': readTime(holder.getAttribute("data-start-time"))
        }
      });

      player.addEventListener("onStateChange", onPlayerStateChange(player, holder));

      holder.addEventListener("click", function(event) {
        if(event.target.tagName == "BUTTON") {
          var e = event.target;
          e = e.parentNode;
          e.style.display = 'none';
          player.playVideo();
        }
       });
    }
  }

  // make our handler available for the youtube script to find
  window.onYouTubeIframeAPIReady = onYouTubeIframeAPIReady;

  addYouTubeScript();
}
