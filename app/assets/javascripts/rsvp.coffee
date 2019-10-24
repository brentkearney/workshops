$(document).on 'turbolinks:load', ->
  return unless $('.rsvp').length > 0

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
    sideBySide: true,
    format: 'YYYY-MM-DD',
    minDate: $('#min_date').val(),
    maxDate: $('#max_date').val(),
    defaultDate: departure_date
  })

  $('#arrival').on 'dp.change', (e) ->
    $('#arrival_date').val(e.date.format('YYYY-MM-DD'));

  $('#departure').on 'dp.change', (e) ->
    $('#departure_date').val(e.date.format('YYYY-MM-DD'));

  $('#rsvp_membership_has_guest').change ->
    $('#guest_disclaimer').toggleClass('mandatory');

  country = $('#rsvp_person_country').val().toLowerCase()

  if country != 'canada'
    $('#canadian-grants').hide();

  if country !in ['canada', 'usa', 'u.s.a.', 'us', 'united states']
    $('#address-region').hide();

  if country == 'canada'
    $('#rsvp_person_region')[0].placeholder = 'Province'

  if country in ['usa', 'u.s.a.', 'us', 'united states']
    $('#rsvp_person_region')[0].placeholder = 'State'

  $('#rsvp_person_country').change ->
    country = $('#rsvp_person_country').val().toLowerCase()
    if country == 'canada'
      $('#canadian-grants').show();
      $('#rsvp_person_region')[0].placeholder = 'Province'
    else
      $('#canadian-grants').hide();
    if country in ['canada', 'usa', 'u.s.a.', 'us', 'united states']
      $('#address-region').show();
    else
      $('#address-region').hide();
    if country in ['usa', 'u.s.a.', 'us', 'united states']
      $('#rsvp_person_region')[0].placeholder = 'State'
