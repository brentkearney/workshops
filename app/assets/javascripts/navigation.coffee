$(document).on 'turbolinks:load', ->
  $('#sidebar-toggle').click (e) ->
    $('.toggle-arrows').toggleClass('fa-rotate-180')

  update_active =(item_id) ->
    $('ul.app-menu').find('a').each (index, element) ->
      $('#' + element.id).removeClass('active')
    $('#' + item_id).addClass('active')

  $('.app-sidebar').click (e) =>
    update_active(e.target.closest('a').id)

  page_class = $('#current-page').attr('class')
  update_active(page_class)
