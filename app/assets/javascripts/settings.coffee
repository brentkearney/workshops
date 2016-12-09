$(document).on 'turbolinks:load', ->
  $('.nav-tabs a').click (e) ->
    $('div.tab-pane').removeClass('active')
    $('div#' + this.id).addClass('active')
