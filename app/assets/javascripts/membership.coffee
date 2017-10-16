$(document).on 'turbolinks:load', ->
  arrival_date = $('#arrival_date').val()

  $('#arrival').datetimepicker({
    inline: true,
    sideBySide: true,
    format: 'YYYY-MM-DD',
    defaultDate: arrival_date
  })

  departure_date = $('#departure_date').val()

  $('#departure').datetimepicker({
    inline: true,
    format: 'YYYY-MM-DD',
    defaultDate: departure_date
  })

  $('#arrival').on 'dp.change', (e) =>
    $('#arrival_date').val(e.date.format('YYYY-MM-DD'));

  $('#departure').on 'dp.change', (e) =>
    $('#departure_date').val(e.date.format('YYYY-MM-DD'));
