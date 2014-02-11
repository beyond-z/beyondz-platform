# Workaround to get Google Analytics working with Turbolinks.  See: http://railsapps.github.io/rails-google-analytics.html
$(document).on 'page:change', ->
  if window._gaq?
    _gaq.push ['_trackPageview']
  else if window.pageTracker?
    pageTracker._trackPageview()
