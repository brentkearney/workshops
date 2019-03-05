$(document).on 'turbolinks:load', ->
  return unless $('.schedule').length > 0

  if $('#earliest_hour').length > 0
    ehour = parseInt( $('#earliest_hour').val(), 10 )
    $('#schedule_start_time_4i option:lt(' + ehour + ')').remove()
    emin = parseInt( $('#earliest_minute').val(), 10 )

    $('#schedule_start_time_4i').click (event) ->
      selected = $('#schedule_start_time_4i option').filter(':selected').text()
      if parseInt(selected, 10) is ehour
        $('#schedule_start_time_5i option:lt(' + emin + ')').remove()
      else
        if $('#schedule_start_time_5i option').size() < 60
          for min in [(emin - 1)..0]
            min = "0#{min}" if min < 10
            $('#schedule_start_time_5i').prepend('<option value="' + min + '">' + min + '</option>')


  if $('#latest_hour').length > 0
    lhour = parseInt( $('#latest_hour').val(), 10 )
    $('#schedule_end_time_4i option:gt(' + lhour + ')').remove()
    lmin = parseInt( $('#latest_minute').val(), 10 )

    $('#schedule_end_time_4i').click (event) ->
      selected = $('#schedule_end_time_4i option').filter(':selected').text()
      if parseInt(selected, 10) is lhour
        $('#schedule_end_time_5i option:gt(' + lmin + ')').remove()
      else
        if $('#schedule_end_time_5i option').size() < 60
          for min in [(lmin + 1)..59]
            min = "0#{min}" if min < 10
            $('#schedule_end_time_5i').append('<option value="' + min + '">' + min + '</option>')


  $('#print-button').click (event) ->
    print()

  if /firefox|msie/i.test(navigator.userAgent)
    $('select').removeClass('form-control')


  publish_schedule =(state) ->
    $.ajax
      url: '/events/' + $('#event-code').text() + '/schedule/publish_schedule'
      type: 'POST'
      dataType: 'html'
      data: { publish_schedule: state }
      success: (data, status, response) ->
        #alert 'Publishing successful! received: ' + data + ' resp:' + response
      error: ->
        alert 'Failed to change publishing status! :('

  $('#publish_schedule').change ->
    if this.checked
      publish_schedule('true')
    else
      publish_schedule('false')


    $('.item-link').click (event) ->
      event.preventDefault()
      desc_id = this.id.replace("link", "description")
      $('#' + desc_id).fadeToggle()


  if $("body.schedule.new").length > 0 || $("body.schedule.edit").length > 0
    date = $('#day').val()
    startHour = $('#schedule_start_time_4i').find(":selected").text()
    startMin = $('#schedule_start_time_5i').find(":selected").text()
    endHour = $('#schedule_end_time_4i').find(":selected").text()
    endMin = $('#schedule_end_time_5i').find(":selected").text()

    jsdate = date.replace(/-/g, '/')
    datestring = jsdate + ' ' + startHour + ':' + startMin + ':00'
    start_time = new Date(datestring)
    datestring = jsdate + ' ' + endHour + ':' + endMin + ':00'
    end_time = new Date(datestring)

    datediff = end_time.getTime() - start_time.getTime()

    $('#schedule_start_time_4i').on 'change', (e) =>
      update_end_time(datediff)

    $('#schedule_start_time_5i').on 'change', (e) =>
      update_end_time(datediff)

    update_end_time = (datediff) ->
      newStartHour = $('#schedule_start_time_4i').find(":selected").text()
      newStartMin = $('#schedule_start_time_5i').find(":selected").text()

      if newStartHour == '23'
        $('#schedule_end_time_4i').val(newStartHour)
        if datediff < 60 * 59 * 1000
          $('#schedule_end_time_5i').val(('0' + (newStartMin + datediff)).slice(-2))
        else
          $('#schedule_end_time_5i').val('59')
      else
        datestring = jsdate + ' ' + newStartHour + ':' + newStartMin + ':00'
        newStartTime = new Date(datestring)
        newEndTime = new Date(newStartTime.getTime() + datediff)
        $('#schedule_end_time_4i').val(('0' + newEndTime.getHours()).slice(-2))
        $('#schedule_end_time_5i').val(('0' + newEndTime.getMinutes()).slice(-2))

      newEndTime
