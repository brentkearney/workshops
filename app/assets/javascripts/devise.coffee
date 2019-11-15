$(window).load ->
  $('.login-content [data-toggle="flip"]').click (e) ->
    $('.login-box').toggleClass('flipped')
