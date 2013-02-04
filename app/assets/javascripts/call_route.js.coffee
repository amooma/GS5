jQuery ->
  $('#call_routes').sortable
    axis: 'y'
    handle: '.handle'
    update: ->
      $.post($(this).data('update-url'), $(this).sortable('serialize'))