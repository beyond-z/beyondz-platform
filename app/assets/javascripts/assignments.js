$(document).ready(function() {

  $('.task_confirm').change(function() {
    var assignment_id = $(this).data("assignment-id");
    var task_id = $(this).data("task-id");
    
    $.ajax({
      url: '/assignments/' + assignment_id + '/tasks/' + task_id + '.json',
      type: 'PATCH',
      data: {
        'task': {
          'user_confirm': this.checked
        }
      }
    });
    return false;
  });

  $('.assign-summary.completed').click(function() {
    $(this).removeClass('completed');
  })
});
