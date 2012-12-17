jQuery ->
  function_name = $('#softkey_softkey_function_id :selected').text()

  if function_name == call_forwarding_function_name
    $('#softkey_call_forward_id').parent().show()
    $('#softkey_number').parent().hide()
  else
    $('#softkey_call_forward_id').parent().hide()
    if (function_name == hold_function_name || function_name == deactivated_function_name)
      $('#softkey_number').parent().hide()
    else
      $('#softkey_number').parent().show()  

  $('#softkey_softkey_function_id').change ->
    $('#softkey_label').parent().show()
    function_name = $('#softkey_softkey_function_id :selected').text()
    if function_name == call_forwarding_function_name
      $('#softkey_call_forward_id').parent().show("slow")
      $('#softkey_number').parent().hide("slow")
    else
      $('#softkey_call_forward_id').parent().hide("slow")
      if (function_name == hold_function_name || function_name == deactivated_function_name)
        $('#softkey_number').parent().hide("slow")
      else
        $('#softkey_number').parent().show("slow") 
