$(document).on 'turbolinks:load', ->
  sign_in_link = $('ul.dropdown-user li a').attr('href')
  if sign_in_link == '/sign_in'
    $('#page-wrapper').css('margin-left','0')
    $('#page-wrapper').css('border-left', 'none')

  $('div.sidebar').find('*').removeClass('active')

  $('a#event-locations-link').click ->
    $('li#event-locations').each (index, element) =>
      $(element).removeClass('active')

    $('span#locations-arrow').toggleClass('arrow')
    $('span#locations-arrow').toggleClass('arrow-down')

  switch path = window.location.pathname
    when '/events' then $('li#all-events').addClass('active')
    when '/events/my_events' then $('li#my-events').addClass('active')
    when '/events/past' then $('li#past-events').addClass('active')
    when '/events/future' then $('li#future-events').addClass('active')
    else
      if path.match(/\/events\/location/)
        $('span#locations-arrow').toggleClass('arrow')
        $('span#locations-arrow').toggleClass('arrow-down')
        location = path.split('/').pop()
        $("li#" + location).addClass('active')
      else if $('body').is('.welcome')
        $('li#home').addClass('active')
      else if $('body').is('.events, .show')
        $('li#event-details').addClass('active')
      else if $('body').is('.events, .schedule')
        $('li#event-schedule').addClass('active')
      else if $('body').is('.events, .memberships')
        $('li#event-memberships').addClass('active')
