$(document).ready(function() {
  $('.approve_task').click(function() {
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
});
