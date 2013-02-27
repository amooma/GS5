# Simple Form Toggle for required fields
$(document).ready ->
  validate_fields = (obj)->
    if ($(obj).val() == "")
      $(obj).addClass "invalid"
    else
      $(obj).removeClass "invalid"

  sel = "input.required, textarea.required"
  $(sel).each (i, e)-> validate_fields(e)
  $(sel).keyup -> validate_fields(this)
