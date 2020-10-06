$(document).ready(function() {
  load_component_video_quiz();
  load_component_compare_and_rank();

  $('.context-notes').popover({
    trigger: 'hover'
  })

  //// Don't AJAX task submittal for now until after workflow is re-assessed 
  // var task_action_box = $('.task-container .action-box');
  // var task_update_submit = '#task-update-student .edit_task input[type=submit]';

  // update task
  // task_action_box.on('click', task_update_submit, function(e){
  //   e.preventDefault();
  //   try
  //   {
  //     var el = $(this);
  //     var form = el.closest('form');
  //     var formData = new FormData(form[0]);

  //     $.ajax({
  //       url: form.attr('action'),
  //       data: formData,
  //       type: 'PATCH',
  //       beforeSend: function() {},
  //       error: function() {},
  //       success: function(data, status, xhr) {
  //         task_action_box.html(data);
  //       },
  //       cache: false,
  //       contentType: false,
  //       processData: false,
  //       xhr: function() {  // Custom XMLHttpRequest
  //         var myXhr = $.ajaxSettings.xhr();
  //         // only update progress for files uploads
  //         if(form.find('.task-file').length)
  //         {
  //           if(myXhr.upload) // Check if upload property exists
  //           {
  //             var progress_bar = $('.file-upload-progress');
  //             progress_bar.removeClass('invisible');
  //             // For handling the progress of the upload
  //             myXhr.upload.addEventListener(
  //               'progress',
  //               function(e) {
  //                 if(e.lengthComputable){
  //                   update_progress_bar(progress_bar, e);
  //                 }
  //               },
  //               false
  //             );
  //           }
  //         }
  //         return myXhr;
  //       }
  //     });
  //   }
  //   catch(e)
  //   {
  //     alert('Unable to update task.');
  //   }

  //   return false;
  // });


  // coach set status on task
  var task_action_box = $('.task-container .action-box');
  var task_update_submit = '#task-update-coach .edit_task input[type=submit]';

  task_action_box.on('click', task_update_submit, function(e){
    var el = $(this);
    var task_action = el.attr('data-task-action');
    var form = el.closest('form');

    // check confirmation only on approve
    if(task_action == 'approve')
    {
      // check if status requires confirmation of approval
      if(el.attr('data-task-status') == 'pending_revision')
      {
        if(!confirm("This task is still awaiting revisions. Are you  sure you want to approve it?"))
        {
          return false;
        }
      }
    }

    // update hidden field with action
    form.find('#task_action').val(task_action);
    
    $.ajax({
      url: form.attr('action'),
      data: form.serializeArray(),
      type: 'PATCH',
      beforeSend: function() {},
      error: function() {},
      success: function(data, status, xhr) {
        task_action_box.html(data);
      }
    });

    return false;
  });

});
