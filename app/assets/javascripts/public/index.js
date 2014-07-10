/*
  On the index, we use embedded videos that need to be resized with the
  screen lest they overlap as the columns change size.

  Doing this in CSS proved to be buggy with the cross-domain iframes, causing
  them to sometimes disappear or hide content.

  So, we'll use javascript instead to change the iframe attributes to match
  the size and aspect ratio of the outer div.

  It needs to run immediately on page load to handle different devices/browser
  sizes and then will also run on window resize to keep it sane dynamically.
*/
$(document).ready(function() {
  var resizeVideos = function() {
    $(".video-box, .big-video-box").each(function(idx, element) {
      var e = $(element);
      $("iframe", element).attr('height', e.width() * 9 / 16);
      $("iframe", element).attr('width', e.width());
    });
  };

  // size it to the current window size
  resizeVideos();

  // size it dynamically too
  $(window).resize(resizeVideos);
});
