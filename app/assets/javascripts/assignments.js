$(document).ready(function() {
  $(".todo-check").change(function() {
    $.post("/assignments/toggle_check",
      {
        "id": $(this).data("todo-id"),
        "is_checked": (this.checked ? "true" : "false"),
      });
  });

  $(".assign-summary.completed").click(function() {
    $(this).removeClass("completed");
  })
});
