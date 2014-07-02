$(document).ready(function() {
  $("input[type=radio]").change(function() {
    $(".form-option-details").hide();
    if(this.checked)
      $("~ .form-option-details", this).show();
  });
});
