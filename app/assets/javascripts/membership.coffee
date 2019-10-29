$(document).on 'turbolinks:load', ->
  return unless $('.memberships').length > 0

  $(".spinner").hide()
  $('#add-members').show()

  arrival_date = $('#arrival_date').val()
  arrival_date or= $('#min_date').val()

  $('#arrival').datetimepicker({
    format: 'YYYY-MM-DD',
    minDate: $('#min_date').val(),
    maxDate: $('#max_date').val(),
    defaultDate: arrival_date
  })

  departure_date = $('#departure_date').val()
  departure_date or= $('#max_date').val()

  $('#departure').datetimepicker({
    format: 'YYYY-MM-DD',
    minDate: $('#min_date').val(),
    maxDate: $('#max_date').val(),
    defaultDate: departure_date
  })

  $('#new-people tr').find('.person-data').each (i, field) ->
    if field.value.length == 0
      $(field).addClass('has-error')

  $('.person-data').change (e) ->
    $('#new-people tr').find('.person-data').each (i, field) ->
      if field.value.length > 0
        $(field).removeClass('has-error')
      else
        $(field).addClass('has-error')

  $('#add-members-submit').click (e) ->
    $('#add-members').hide()
    $(".spinner").show()


  # memberships invite page buttons
  checkall = (status) ->
    for i,elm of $("." + status)
      elm.checked=true

  checknone = (status) ->
    for i,elm of $("." + status)
      elm.checked=false

  checkinvert = (status) ->
    for i,elm of $("." + status)
      elm.checked = !elm.checked

  $('.all-button').click (e) ->
    status = /^(.+)-all$/.exec(e.target.id)[1]
    checkall(status)

  $('.none-button').click (e) ->
    status = /^(.+)-none$/.exec(e.target.id)[1]
    checknone(status)

  $('.invert-button').click (e) ->
    status = /^(.+)-invert$/.exec(e.target.id)[1]
    checkinvert(status)
