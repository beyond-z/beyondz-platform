// From: http://stackoverflow.com/questions/439463/how-to-get-get-and-post-variables-with-jquery

function getQueryParams(qs) {
    qs = qs.split("+").join(" ");
    var params = {},
        tokens,
        re = /[?&]?([^=]+)=([^&]*)/g;

    while (tokens = re.exec(qs)) {
        params[decodeURIComponent(tokens[1])]
            = decodeURIComponent(tokens[2]);
    }

    return params;
}

var $_GET = getQueryParams(document.location.search);

// licensed code ends

// If we've been asked to redirect, do it now, busting out of the iframe.
if('out_to_lms' in $_GET)
  window.top.location.href = $_GET['out_to_lms'];
