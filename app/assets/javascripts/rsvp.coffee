$(document).on 'turbolinks:load', ->
  arrival_date = $('#arrival_date').val()
  arrival_date or= $('#min_date').val()

  $('#arrival').datetimepicker({
    inline: true,
    sideBySide: true,
    format: 'YYYY-MM-DD',
    minDate: $('#min_date').val(),
    maxDate: $('#max_date').val(),
    defaultDate: arrival_date
  })

  departure_date = $('#departure_date').val()
  departure_date or= $('#max_date').val()

  $('#departure').datetimepicker({
    inline: true,
    format: 'YYYY-MM-DD',
    minDate: $('#min_date').val(),
    maxDate: $('#max_date').val(),
    defaultDate: departure_date
  })
