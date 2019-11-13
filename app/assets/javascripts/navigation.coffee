$(document).on 'turbolinks:load', ->
  $('#sidebar-toggle').click (e) ->
    $('.toggle-arrows').toggleClass('fa-rotate-180')

  remove_active =->
    $('ul.app-menu').find('a').each (index, element) ->
      if element.id
        $('#' + element.id).removeClass('active')

  expand_menu =(item) =>
    item.closest('li').addClass('is-expanded')

  year_location =->
    path = window.location.pathname
    found = false
    if path.match(/location/)
      expand_menu($('#location-events'))
      #location = path.match(/location\/(\w+)/)[1] # excludes hyphens in name
      location = path.split('/').pop()
      $('#' + location + '-events').addClass('active')
      found = true

    if path.match(/year/)
      expand_menu($('#year-events'))
      year = path.match(/year\/(\d{4})/)[1]
      $('#' + year + '-events').addClass('active')
      found = true

    return found

  update_active =(item_id) ->
    remove_active()
    if !year_location()
      if item_id.length > 0
        item = $('#' + item_id)
        expand_menu(item)
        item.addClass('active')

  page_class = $('#current-page').attr('class')
  update_active(page_class)
