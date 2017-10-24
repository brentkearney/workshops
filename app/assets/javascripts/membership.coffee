$(document).on 'turbolinks:load', ->
  arrival_date = $('#arrival_date').val()
  $('#arrival').datetimepicker({
    format: 'YYYY-MM-DD',
    defaultDate: arrival_date
  })

  departure_date = $('#departure_date').val()
  $('#departure').datetimepicker({
    format: 'YYYY-MM-DD',
    defaultDate: departure_date
  })
