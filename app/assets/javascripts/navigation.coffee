$(document).on 'turbolinks:load', ->

  # Display new feature modal
  $('#new-feature-notice').modal('show');

  $('#sidebar-toggle').click (e) ->
    $('.toggle-arrows').toggleClass('fa-rotate-180')

  toggle_sidebar_cookie =(state) ->
    $.ajax
      url: '/home/toggle_sidebar'
      type: 'POST'
      dataType: 'html'
      data: { toggle: state }
      success: (data, status, response) ->
        #alert 'Toggle successful! received: ' + data + ' resp:' + response
      error: ->
        #alert 'Failed to change toggle status! :('

  $('[data-toggle="sidebar"]').click (e) ->
    e.preventDefault();
    $('.app').toggleClass('sidenav-toggled');
    state = $('.app').hasClass('sidenav-toggled')
    toggle_sidebar_cookie(state)

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
      if item_id
        item = $('#' + item_id)
        expand_menu(item)
        item.addClass('active')

  $('.treeview-item').click (e) ->
    remove_active()
    year_location()
    $(e.target).closest('li').addClass('active')

  page_class = $('#current-page').attr('class')
  update_active(page_class)

  if $(window).width() < 600
    toggle_sidebar_cookie(false)
    $('.app').removeClass('sidenav-toggled');

  if $('.app').hasClass('sidenav-toggled')
    $('.toggle-arrows').addClass('fa-rotate-180')
