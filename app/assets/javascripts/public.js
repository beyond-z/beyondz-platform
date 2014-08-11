// JavaScript that is common to the public views
//
// This is a manifest file that'll be compiled into application.js, which will
// include all the files listed below.
//
//= require_self
//= require_directory ./public

$(document).ready(function() {

  // automatically stop video when modal is closed
  var intro_video = $('#intro-video');
  intro_video.on('hidden.bs.modal', function(e) {
    var iframe = intro_video.find('iframe');
    var vidsrc = iframe.attr('src');
    // sets the source to nothing, stopping the video
    iframe.attr('src',''); 

    vidsrc = vidsrc.replace('?autoplay=1', ''); // don't want it to autoplay in background when hidden

    // sets it back to the correct link so that it reloads immediately on the next window open
    iframe.attr('src', vidsrc);
  });

  intro_video.on('shown.bs.modal', function(e) {
    var iframe = intro_video.find('iframe');
    var vidsrc = iframe.attr('src');

    // cause it to autoplay when it shows
    iframe.attr('src', vidsrc + '?autoplay=1');
  });

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
  var resizeVideos = function() {
    $(".video-box").each(function(idx, element) {
      var e = $(element);
      $("iframe", element).attr('height', e.width() * 9 / 16);
      $("iframe", element).attr('width', e.width());
    });
  };

  // size it to the current window size
  resizeVideos();

  // size it dynamically too
  $(window).resize(resizeVideos);


  var setScrollClass = function() {
    $("body")[$(window).scrollTop() <= 0 ? "removeClass" : "addClass"]("scrolled-down");
  };

  $(window).scroll(setScrollClass);
  setScrollClass(); // ensure it is correctly set upon page load too
});
