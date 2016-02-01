$(document).ready ->
  sign_in_link = $('ul.dropdown-user li a').attr('href')
  if sign_in_link == '/sign_in'
    $('#page-wrapper').css('margin-left','0')
    $('#page-wrapper').css('border-left', 'none')

  $('div.sidebar').find('*').removeClass('active')

  switch path = window.location.pathname
    when '/events' then $('a#all-events').addClass('active')
    when '/events/my_events' then $('a#my-events').addClass('active')
    when '/events/past' then $('a#past-events').addClass('active')
    when '/events/future' then $('a#future-events').addClass('active')
    else
      if path.match(/\/events\/location/)
        location = path.split('/').pop()
        $("#" + location).addClass('active')
      else if $('body').is('.welcome')
        $('a#home').addClass('active')
      else if $('body').is('.events, .show')
        $('a#event-details').addClass('active')
      else if $('body').is('.events, .schedule')
        $('a#event-schedule').addClass('active')
      else if $('body').is('.events, .memberships')
        $('a#event-memberships').addClass('active')
