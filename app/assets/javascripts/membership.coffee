$(document).on 'turbolinks:load', ->
  return unless $('.memberships').length > 0

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
