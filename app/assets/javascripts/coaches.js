$(document).ready(function() {
  $('.approve-task').click(function() {
    var task_id = $(this).data("task-id");
    
    $.ajax({
      url: '/coaches/approve_task' + '.json',
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
