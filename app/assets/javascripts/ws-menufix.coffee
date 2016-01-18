$(document).ready ->
  sign_in_link = $('ul.dropdown-user li a').attr('href')
  if sign_in_link == '/sign_in'
    $('#page-wrapper').css('margin-left','0')
    $('#page-wrapper').css('border-left', 'none')

  $('div.sidebar').find('*').removeClass('active')

  switch window.location.pathname
    when '/events/all' then $('a#all-events').addClass('active')
    when '/events/scope/future' then $('a#future-events').addClass('active')
    when '/events/scope/past' then $('a#past-events').addClass('active')
    when '/events' then $('a#your-events').addClass('active')
    else
      if $('body').is('.welcome')
        $('a#home').addClass('active')
      else if $('body').is('.events, .show')
        $('a#event-details').addClass('active')
      else if $('body').is('.events, .schedule')
        $('a#event-schedule').addClass('active')
      else if $('body').is('.events, .memberships')
        $('a#event-memberships').addClass('active')

