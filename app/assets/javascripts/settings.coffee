$(document).on 'turbolinks:load', ->
  $('.nav-tabs a').click (e) ->
    $('div.tab-pane').removeClass('active')
    $(this).tab('show')
    $('div#' + this.id).addClass('active')
