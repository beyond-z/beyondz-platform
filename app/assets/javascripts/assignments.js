$(document).ready(function() {
  $(".todo-check").change(function() {
    $.post("/assignments/set_completed",
      {
        "id": $(this).val(),
        "completed": (this.checked ? "true" : "false"),
      });
  });

  $(".assign-summary.completed").click(function() {
    $(this).removeClass("completed");
  })
});
