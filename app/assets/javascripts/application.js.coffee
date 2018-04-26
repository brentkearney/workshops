$(document).on 'turbolinks:load', ->
  window.MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
