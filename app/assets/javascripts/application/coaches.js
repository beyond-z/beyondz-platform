$(document).ready(function() {
  $('.approve-task').click(function() {
    var task_id = $(this).data("task-id");
    
    $.ajax({
      url: '/coaches/approve_task' + '.json',
      success: function() { alert("Task approved."); },
      type: 'PATCH',
      data: {
        'task': {
          "id" : task_id
        }
      }
    });
    return false;
  });

  $('.request-task-revisions').click(function() {
    var task_id = $(this).data("task-id");
    
    $.ajax({
      url: '/coaches/request_task_revisions' + '.json',
      success: function() { alert("Revisions requested. Please remember to leave a comment for the student giving them tips on how to move forward."); },
      type: 'PATCH',
      data: {
        'task': {
          "id" : task_id
        }
      }
    });
    return false;
  });

});
