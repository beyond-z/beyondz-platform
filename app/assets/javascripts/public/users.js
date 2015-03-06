// this displays subsequent details divs when the preceding radio
// box is checked. Lets us easily ask for details for the various options
// on the sign up form.
$(document).ready(function() {
  function getGroup(e) {
    while( !$(e).hasClass("form-group"))
      e = e.parentNode;
    return e;
  }

  // This gets everything in a form group with a name, suitable for disabling
  // or enabling, but stops at the nested form groups.
  //
  // e is the starting point.
  // operation is the callback function, called on each suitable child.
  // descend tells if we need to dig into form-option-details. Always set
  // to true on a top level call.
  function onChildNamedElements(e, operation, descend) {
    var children = e.childNodes;
    for(var i = 0; i < children.length; i++) {
      var child = children[i];
      // we only want to affect [name] - stuff submitted to the server.
      if(child.hasAttribute && child.hasAttribute("name"))
        operation(child);
      if(!descend && $(child).hasClass("form-option-details"))
        continue;
      // we need to stop descending if we're into another form group
      onChildNamedElements(child, operation, !$(child).hasClass("form-group"));
    }
  }

  $("input[type=radio]").change(function() {
    var ctx = $(".form-option-details", getGroup(this));
    ctx.hide();
    // disable all hidden elements too
    $("[name]", ctx).prop('disabled', 'disabled');
    if(this.checked) {
      ctx = $("~ .form-option-details", this).filter(":first");
      ctx.show();
      onChildNamedElements(ctx[0], function(e) { e.removeAttribute("disabled"); }, true);
    }
  });

  // also showing the current selection details, if there is one
  var showing = $("input[type=radio]:checked ~ .form-option-details");
  showing.show();

  // disable all sub-options by default so they don't get sent to the controller
  $("input[type=radio] ~ .form-option-details [name]").prop('disabled', 'disabled');
  // but enable the ones under checked items
  var elements = showing.get();
  for(var idx = 0; idx < elements.length; idx++) {
    var ctx = elements[idx];
    onChildNamedElements(ctx, function(e) { e.removeAttribute("disabled"); }, true);
  }
});
