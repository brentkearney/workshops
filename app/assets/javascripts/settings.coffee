$(document).on 'turbolinks:load', ->
  return unless ($(".settings").length > 0)

  $('.nav-tabs a').click (e) ->
    $('div.tab-pane').removeClass('active')
    $('div#' + this.id).addClass('active')
