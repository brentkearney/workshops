$(document).on 'turbolinks:load', ->
  return unless $('.rsvp').length > 0

  region_country =(country) ->
    return (country in ['canada', 'usa', 'u.s.a.', 'us', 'u.s.', 'united states', 'united states of america']);

  change_region_placeholder =(country) ->
    if country == 'canada'
      $('#rsvp_person_region')[0].placeholder = 'Province';
    else
      $('#rsvp_person_region')[0].placeholder = 'State';

  show_or_hide_region =(country) ->
    if region_country(country)
      $('#address-region').show();
      change_region_placeholder(country);
    else
      $('#address-region').hide();

  country = $('#rsvp_person_country').val().toLowerCase();

  if country != 'canada'
    $('#canadian-grants').hide();

  show_or_hide_region(country);

  $('#rsvp_person_country').change ->
    country = $('#rsvp_person_country').val().toLowerCase();
    show_or_hide_region(country);
    if country == 'canada'
      $('#canadian-grants').show();
    else
      $('#canadian-grants').hide();


  $('#rsvp_membership_has_guest').change ->
    $('#rsvp_membership_guest_disclaimer').toggleClass('mandatory');
