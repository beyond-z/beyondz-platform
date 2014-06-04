// JavaScript that is common to the general application (non-admin)
//
// This is a manifest file that'll be compiled into application.js, which will
// include all the files listed below.
//
//= require_self


// update general progress bars
function update_progress_bar(progress_container, event)
{
  var progress_bar = $(progress_container).find('.progress-bar');
  progress_bar.attr({
    'aria-valuenow': event.loaded,
    'aria-valuemax': event.total,
    style: 'width: ' + event.loaded + '%;'
  });
  progress_bar.find('.sr-only').html(event.loaded + '% Complete');
}


$(document).ready(function() {
 
});