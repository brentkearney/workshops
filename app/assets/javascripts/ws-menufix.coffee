ready = ->
  sign_in_link = $('ul.dropdown-user li a').attr('href')
  if sign_in_link == '/sign_in'
    $('#page-wrapper').css('margin-left','0')
    $('#page-wrapper').css('border-left', 'none')

  $('div.sidebar').find('*').removeClass('active')

  $('a#event-locations-link').click ->
    $('li#event-locations').each (index, element) =>
      $(element).removeClass('active')

  $('a#event-years-link').click ->
    $('li#event-years').each (index, element) =>
      $(element).removeClass('active')

  $('a#event-members-link').click ->
    $('li#event-memberships').each (index, element) =>
      $(element).removeClass('active')

    $('span#locations-arrow').toggleClass('arrow')
    $('span#locations-arrow').toggleClass('arrow-down')

  path = window.location.pathname
  if path == '/events'
      $('li#all-events').addClass('active')
  else if path == '/events/my_events'
      $('li#my-events').addClass('active')
  else if path.match(/events\/past/)
      $('li#past-events').addClass('active')
  else if path.match(/events\/future/)
      $('li#future-events').addClass('active')
  else if path.match(/events\/(.+)\/schedule/)
      $('li#event-schedule').addClass('active')
  else if path.match(/events\/(.+)\/memberships/)
      $('li#event-members-list').addClass('active')
      if path.match((/events\/(.+)\/memberships\/add/))
        $('li#event-members-list').removeClass('active')
        $('li#event-members-add').addClass('active')
  else if path.match(/events\/(.+)$/)
      $('li#event-details').addClass('active')

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


$(document).ready(ready)
$(document).on('turbolinks:load', ready)
