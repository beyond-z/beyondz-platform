$(document).ready(function() {
    // make the readonly form actually readonly by prohibiting submissions and restricting edits
    $('#enrollment-form-holder.readonly form').submit(function() { return false; });
    $('#enrollment-form-holder.readonly input, #enrollment-form-holder.readonly textarea').attr('readonly', 'readonly');


    // update the charater counter on textareas that have a maxlength property:
    function updateCountdown(el) {
      var maxlength = $(el).prop('maxlength')
      var currentlength =  $(el).val().length;
      $(el).next('.countdown').text(currentlength + '/' + maxlength);
    }
    // add a character counter textareas that have a maxlength property and make the count update as users type.
    $('[maxlength]').change(function(){updateCountdown(this)}).keyup(function(){updateCountdown(this)}).after('<span class="countdown"></span>').change();

    // set autofocus in case browser doesn't support html5
      if (!('autofocus' in document.createElement('input'))) {
        $(['autofocus']).focus();
      }
    
    // expand fields based on radio button selection:
    $('.expandable').children('.extra').hide();
    $('.complex :radio').click(function(){
      var parent = $(this).closest('.expandable');
      $(parent).siblings('.expandable').children('.extra').slideUp('fast')
      $(parent).children('.extra').slideDown('fast');
    });
    
    // Generate TOC:
    $('h2').not('.sr-only, #form-almost-done h2').each(function() {
      $('#jumplinks').append('<li class="page-jump '+$(this).closest('div').prop('class')+'"><a href="#'+$(this).closest('div').prop('id')+'"><div class="jump-icon"></div>'+$(this).text()+'</a></li>');
    });


    // hide all other fields until one of the applying as is selected
    if(!$('#position_coach').prop('checked') && !$('#position_student').prop('checked'))
      $('.coach, .student').hide(); // none are selected, hide everything
    else {
      // one is selected but not the other, so need to be more careful about what we hide
      if(!$('#position_coach').prop('checked'))
        $('.coach:not(.student)').fadeOut('fast');
      if(!$('#position_student').prop('checked'))
        $('.student:not(.coach)').fadeOut('fast');
    }
    
    // Show or hide questions based on user type and program upon selection change:
    $('[value=student]').click(function(){
      $('.coach').fadeOut('fast');
      $('.student').fadeIn('fast');
    });
    $('[value=coach]').click(function(){
      $('.student').fadeOut('fast');
      $('.coach').fadeIn('fast');
    });

    // Hide "other" checkbox/radio detail inputs 
    //$('input.other').hide();


    // Sets a timer whenever data is changed which updates the server
    // to ensure the user's data are transparently saved if they stop
    // and come back later

    var saveTimer = null;
    function saveEnrollment() {
      if(saveTimer === null) {
        // the timer keeps it from pounding the server too hard
        // if someone does rapid changes
        saveTimer = setTimeout(function() {
          var form = $('#enrollment-form-holder form');
          $.post(form[0].action, form.serialize());
          saveTimer = null;
        }, 1000);
      }
    }

    $('input, textarea').change(saveEnrollment);

    // We'll also do it on keydown to save more frequently
    // on the long answer portions
    $('input, textarea').keydown(saveEnrollment);
    
  // replace programming languages (testing only) with actual majors
  var majors = [
    'ActionScript',
    'AppleScript',
    'Asp',
    'BASIC',
    'C',
    'C++',
    'Clojure',
    'COBOL',
    'ColdFusion',
    'Erlang',
    'Fortran',
    'Groovy',
    'Haskell',
    'Java',
    'JavaScript',
    'Lisp',
    'Perl',
    'PHP',
    'Python',
    'Ruby',
    'Scala',
    'Scheme'
  ];
  $('#major').autocomplete({
    source: majors
  });
});
