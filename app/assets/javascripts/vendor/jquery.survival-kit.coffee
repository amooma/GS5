Array.prototype.empty = ->
  if this.length <= 0
    return true
  else
    return false

$.ns('sk').add {
  # Search Box Helper
  searchBox: ->
    input = $('input.text', this)
    default_mes = input.val()
    input.focus(->
      if input.val() == default_mes
        input.val ''
    ).blur(->
      if input.val() == ''
       input.val default_mes
    )
    
  # Simple Form Style Helper.
  simpleForms: ->
    max = 0
    labels = $("div:not(.boolean) > label", this)
    hints  = $("div:not(.boolean) > .hint", this)
    labels.each ->
      if $(this).width() > max
        max = $(this).width()
    $('> .hint.padded', this).css 'padding-left' : max
    
    # Get the horizontal-spacing (set on the css.)
    horizontal_spacing = parseInt(labels.first().css('margin-right'))
    
    hints.css 'padding-left' : (max + horizontal_spacing)
    $('.actions', this).css 'padding-left' : (max + horizontal_spacing)
    labels.width(max)
}
