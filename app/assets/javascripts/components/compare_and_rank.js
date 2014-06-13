function load_component_compare_and_rank()
{
  $("#compare-and-rank .rating").jRating({
    rateMax: 5,
    step: true,
    bigStarsPath: '/images/jRating/stars.png',
    smallStarsPath: '/images/jRating/small.png',
    sendRequest: false,
    canRateAgain: true,
    showRateInfo: true,
    nbRates: 5,
    onClick: function(element, rate) {
      //alert(rate);
    }
  });
} 