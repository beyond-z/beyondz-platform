function load_component_compare_and_rank()
{
  var rating_stars = $("#compare-and-rank .rating");

  rating_stars.jRating({
    rateMax: 5,
    step: true,
    bigStarsPath: '/images/jRating/stars.png',
    smallStarsPath: '/images/jRating/small.png',
    sendRequest: false,
    canRateAgain: true,
    showRateInfo: false,
    nbRates: 5,
    onClick: function(element, rate) {
      var target_field = $(element).attr('data-id');
      $('input[data-target=' +  target_field + ']').val(rate);
    }
  });
} 