// JavaScript that is common to the general application (non-admin)
//
// This is a manifest file that'll be compiled into application.js, which will
// include all the files listed below.
//
//= require_self

$(document).ready(function() {

  var task_action_box = $('.task-container .action-box');
  var task_update_submit = '#task_update .edit_task input[type=submit]';
  var task_done_submit = '#task_done .edit_task input[type=submit]';


  function upload_progress(e){
    //console.log('progress');
    if(e.lengthComputable)
    {
      // console.log('found compute');
      // console.log(e.loaded);
      // console.log(e.total);
      $('.progress .progress-bar').attr({
        'aria-valuenow': e.loaded,
        'aria-valuemax': e.total,
        style: 'width: ' + e.loaded + '%;'
      });
      $('.progress .progress-bar .sr-only').html(e.loaded + '% Complete');
    }
  }

  // update task
  task_action_box.on('click', task_update_submit, function(e){
    e.preventDefault();
    try{
      var el = $(this);
      var form = el.closest('form');

      //console.log(form);

      var formData = new FormData(form[0]);

      $.ajax({
        url: form.attr('action'),
        //data: form.serializeArray(),
        data: formData,
        type: 'PATCH',
        beforeSend: function() {
        },
        error: function() {},
        success: function(data, status, xhr) {
          task_action_box.html(data);
        },
        cache: false,
        contentType: false,
        processData: false,
        xhr: function() {  // Custom XMLHttpRequest
          var myXhr = $.ajaxSettings.xhr();
          // only update progress for files uploads
          if(form.find('.task-file').length)
          {
            if(myXhr.upload) // Check if upload property exists
            {
              $('.progress').removeClass('invisible');
              // For handling the progress of the upload
              myXhr.upload.addEventListener('progress',upload_progress, false);
            }
          }
          return myXhr;
        }
      });
    }
    catch(e)
    {
      console.log(e);
      // display problem...
    }

    return false;
  });


  // "submit" task
  task_action_box.on('click', task_done_submit, function(e){
    var el = $(this);
    var form = el.closest('form');

    $.ajax({
      url: form.attr('action'),
      data: form.serializeArray(),
      type: 'PATCH',
      beforeSend: function() {
      },
      error: function() {},
      success: function(data, status, xhr) {
        task_action_box.html(data);
      }
    });

     return false;
  });
 
});