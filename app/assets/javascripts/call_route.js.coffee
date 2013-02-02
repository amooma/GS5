jQuery ->
  $("table tbody").sortable
    axis: 'y'
    handle: '.handle'
    update: ->
      $.post('call_routes/sort', $(this).sortable('serialize'))