// this displays subsequent details divs when the preceding radio
// box is checked. Lets us easily ask for details for the various options
// on the sign up form.
$(document).ready(function() {
  // Get the parent element with the form-group class, which holds the various mutex options
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

      // The browser doesn't like two things with the same name actually
      // being checked, and jQuery's [checked] looks for the checked property
      // rather than the html attribute, so it skips us too. We check it again -
      // if we're showing something and the html says check it, we check it!
      if(child.hasAttribute && child.hasAttribute("checked") && !child.checked) {
        child.checked = true;
        showCurrentCheckedChildren(child.parentNode);
      }
      // we need to stop descending if we're into another form group
      if(!descend && $(child).hasClass("form-option-details"))
        continue;
      onChildNamedElements(child, operation, descend && !$(child).hasClass("form-group"));
    }
  }

  // Show everything under the currently checked thing, recursively
  function showCurrentCheckedChildren(ctx) {
      var showing = $("input[type=radio]:checked ~ .form-option-details, .controls-details:checked ~ .form-option-details", ctx);
      showing.show();

      // we also need to enable the fields that are showing
      var elements = showing.get();
      for(var idx = 0; idx < elements.length; idx++) {
        var ctx = elements[idx];
        onChildNamedElements(ctx, function(e) { e.removeAttribute("disabled"); }, true);
      }
  }

  $("input[type=radio], .controls-details").change(function() {
    var ctx = $(".form-option-details", getGroup(this));
    ctx.hide();
    // disable all hidden elements too
    $("[name]", ctx).prop('disabled', 'disabled');
    if(this.checked) {
      // show and enable the top level items
      ctx = $("~ .form-option-details", this).filter(":first");
      ctx.show();
      onChildNamedElements(ctx[0], function(e) { e.removeAttribute("disabled"); }, true);

      // then descend recursively
      showCurrentCheckedChildren(ctx[0]);
    }
  });

  // disable all sub-options by default so they don't get sent to the controller
  $(".form-option-details [name]").prop('disabled', 'disabled');

  // also showing the current selection details, if there is one
  showCurrentCheckedChildren(null); // null context == whole page
});
