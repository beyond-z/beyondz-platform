$(document).ready(function() {
  function act_upon_task(action, on_success) {
    return function() {
      var task_id = $(this).data("task-id");
      var student_id = $(this).data("student-id");
      
      $.ajax({
        url: '/coach/students/' + student_id + '/tasks/' + task_id + '.json',
        success: on_success,
        type: 'PATCH',
        data: {
          "task_state" : action
        }
      });
      return false;
    };
  }

  $('.approve-task').click(act_upon_task("approve", function() {
    alert("Approved!");
  }));
  $('.request-task-revisions').click(act_upon_task("request_revision", function() {
    alert("Revisions requested. Please remember to leave a comment for the student giving them tips on how to move forward.");
  }));
});
