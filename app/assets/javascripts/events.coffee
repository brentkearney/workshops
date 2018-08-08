$(document).on 'turbolinks:load', ->
  return unless $('.events').length > 0

  if $("body.events.edit").length > 0
    $('#start_date').datetimepicker({
      format: 'YYYY-MM-DD'
    })

    $('#end_date').datetimepicker({
      useCurrent: false,
      format: 'YYYY-MM-DD'
    })

    $('#start_date').on 'dp.change', (e) =>
      $('#end_date').data("DateTimePicker").minDate(e.date);

    $('#end_date').on 'dp.change', (e) =>
      $('#start_date').data('DateTimePicker').maxDate(e.date);
