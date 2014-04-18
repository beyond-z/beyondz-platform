$(document).ready(function() {
  $(".todo-check").change(function() {
    $.post("/assignments/set_completed",
      {
        "id": $(this).data("todo-id"),
        "completed": (this.checked ? "true" : "false"),
      });
  });

  $(".assign-summary.completed").click(function() {
    $(this).removeClass("completed");
  })
});
