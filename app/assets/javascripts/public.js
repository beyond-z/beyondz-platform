// JavaScript that is common to the public views
//
// This is a manifest file that'll be compiled into application.js, which will
// include all the files listed below.
//
//= require_self
//= require_directory ./public

$(document).ready(function() {

  // automatically stop video when modal is closed
  $('#intro-video').on('hidden.bs.modal', function(e) {
    var iframe = $('#intro-video').find('iframe');
    var vidsrc = iframe.attr('src');
    console.log(vidsrc);
    // sets the source to nothing, stopping the video
    iframe.attr('src',''); 

    vidsrc = vidsrc.replace('?autoplay=1', ''); // don't want it to autoplay in background when hidden

    // sets it back to the correct link so that it reloads immediately on the next window open
    iframe.attr('src', vidsrc);
  });

  $('#intro-video').on('shown.bs.modal', function(e) {
    var iframe = $('#intro-video').find('iframe');
    var vidsrc = iframe.attr('src');

    // cause it to autoplay when it shows
    iframe.attr('src', vidsrc + '?autoplay=1');
  });
});
