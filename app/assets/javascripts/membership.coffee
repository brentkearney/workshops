$(document).on 'turbolinks:load', ->
  return unless $('.memberships').length > 0

  $(".spinner").hide()
  $('#add-members').show()

  # Memberships list
  # hide shown tab-pane if member name is re-clicked
  $('a[data-toggle="list"]').click (e) ->
    $(e.target.hash).toggle()
    # e.target.classList.remove('active')

  arrival_date = $('#arrival_date').val()
  arrival_date or= $('#min_date').val()

  #$('#arrival').datetimepicker({
  #  format: 'YYYY-MM-DD',
  #  minDate: $('#min_date').val(),
  #  maxDate: $('#max_date').val(),
  #  defaultDate: arrival_date
  #})

  departure_date = $('#departure_date').val()
  departure_date or= $('#max_date').val()

  #$('#departure').datetimepicker({
  #  format: 'YYYY-MM-DD',
  #  minDate: $('#min_date').val(),
  #  maxDate: $('#max_date').val(),
  #  defaultDate: departure_date
  #})

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

  # Enable tooltips & popovers
  $('[data-toggle="popover"]').popover()
  $('[data-toggle="tooltip"]').tooltip()

  # Memberships invite page buttons
  # Check All
  checkall = (status) ->
    for i,elm of $("." + status)
      elm.checked=true

  # Check None
  checknone = (status) ->
    for i,elm of $("." + status)
      elm.checked=false

  # Invert Selection
  checkinvert = (status) ->
    for i,elm of $("." + status)
      elm.checked = !elm.checked

  # Get attendance status of the Select button clicked
  $('.all-button').click (e) ->
    status = /^(.+)-all$/.exec(e.target.id)[1]
    checkall(status)

  $('.none-button').click (e) ->
    status = /^(.+)-none$/.exec(e.target.id)[1]
    checknone(status)

  $('.invert-button').click (e) ->
    status = /^(.+)-invert$/.exec(e.target.id)[1]
    checkinvert(status)

  # Get attendance status of the Submit button clicked & display confirmation
  $('.submit-button').click (e) ->
    status = /^(.+)-submit$/.exec(e.target.id)[1]
    msg = 'This will send all selected Not Yet Invited Members an email, inviting them to attend this workshop. Are you sure you want to proceed?'
    if status != 'not-yet-invited'
      msg = 'This will send all selected ' + status[0].toUpperCase() + status[1..-1] + ' Members an email, reminding them them to respond to the previously sent invitation. Are you sure you want to proceed?'

    return confirm(msg)

  # Display new feature modal
  $('#new-feature-notice').modal('show');
