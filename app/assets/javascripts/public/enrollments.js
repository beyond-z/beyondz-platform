$(document).ready(function() {
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


    // hide all other fields until one of the applying as is selected
    if(!$('#position_coach').prop('checked'))
      $('.coach').fadeOut('fast');
    if(!$('#position_student').prop('checked'))
      $('.student').fadeOut('fast');
    
    // Show or hide questions based on user type and program:
    $('[value=student]').click(function(){
      console.log('student');
      $('.coach').fadeOut('fast');
      $('.student').fadeIn('fast');
    });
    $('[value=coach]').click(function(){
      $('.student').fadeOut('fast');
      $('.coach').fadeIn('fast');
    });
    
    // Generate TOC:
    $('h2').not('.sr-only, #form-almost-done h2').each(function() {
      $('#jumplinks').append('<li class="page-jump"><a href="#'+$(this).closest('div').prop('id')+'"><div class="jump-icon"></div>'+$(this).text()+'</a></li>');
    });

    // Hide "other" checkbox/radio detail inputs 
    //$('input.other').hide();
    
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
