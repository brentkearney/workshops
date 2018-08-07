$(document).on 'turbolinks:load', ->
  if (!($(".settings").length > 0))
    return;

  $('.nav-tabs a').click (e) ->
    $('div.tab-pane').removeClass('active')
    $('div#' + this.id).addClass('active')
