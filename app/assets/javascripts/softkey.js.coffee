jQuery ->
  $("table tbody").sortable
    axis: 'y'
    handle: '.handle'
    update: ->
      $.post('/softkeys/sort', $(this).sortable('serialize'))