// this displays subsequent details divs when the preceding radio
// box is checked. Lets us easily ask for details for the various options
// on the sign up form.
$(document).ready(function() {
  $("input[type=radio]").change(function() {
    $(".form-option-details").hide();
    if(this.checked)
      $("~ .form-option-details", this).show();
  });
});
