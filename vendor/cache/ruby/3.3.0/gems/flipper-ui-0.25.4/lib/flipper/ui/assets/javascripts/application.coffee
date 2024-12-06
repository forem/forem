$ ->
  $(document).on('click', '.js-toggle-trigger', ->
    $container = $(this).closest('.js-toggle-container')
    $container.toggleClass('toggle-on')
  )
