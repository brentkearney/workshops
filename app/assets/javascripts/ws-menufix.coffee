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

  path = window.location.pathname
  if path == '/events' then $('li#all-events').addClass('active')
  if path == '/events/my_events' then $('li#my-events').addClass('active')
  if path.match(/events\/past/) then $('li#past-events').addClass('active')
  if path.match(/events\/future/) then $('li#future-events').addClass('active')

  if path.match(/location/)
    $('span#locations-arrow').toggleClass('arrow')
    $('span#locations-arrow').toggleClass('arrow-down')
    location = path.split('/').pop()
    $("li#" + location).addClass('active')

  if path.match(/year/)
    $('span#years-arrow').toggleClass('arrow')
    $('span#years-arrow').toggleClass('arrow-down')
    year = path.match(/year\/(\d{4})/)
    $("li#year-" + year[1]).addClass('active')
