$(window).load ->
  return unless $('.devise').length > 0

  $('.login-content [data-toggle="flip"]').click (e) ->
    $('.login-box').toggleClass('flipped')
