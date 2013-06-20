 $(document).ready(function(){
     if($('#call_forward_call_forward_case_id').val() != "3"){
        $("#timeout_div").css('display','none');
     }
     else{
        $("#timeout_div").css('display','block');
     }
     $('#call_forward_call_forward_case_id').change(function(){
        if($(this).val() != "3"){
          $("#timeout_div").css('display','none');
        }
        else{
          $("#timeout_div").css('display','block');
        }
     })

    var voicemail_pattern = /VoicemailAccount$/;

    if($('#call_forward_call_forwarding_destination').val()) {

        if($('#call_forward_call_forwarding_destination').val() == ":PhoneNumber"){
            $("#destination_phone_number").attr('name', 'call_forward[destination]');
            $("#destination_greeting").attr('name', 'disabled');
            $("#destination_phone_number_div").css('display','block');
            $("#destination_greeting_div").css('display','none');

         }
        else if ($('#call_forward_call_forwarding_destination').val().match(voicemail_pattern)){
            $("#destination_phone_number").attr('name', 'disabled');
            $("#destination_greeting").attr('name', 'call_forward[destination]');
            $("#destination_phone_number_div").css('display','none');
            $("#destination_greeting_div").css('display','block');
         } 
         else {
            $("#destination_phone_number").attr('name', 'disabled');
            $("#destination_greeting").attr('name', 'disabled');
            $("#destination_phone_number_div").css('display','none');
            $("#destination_greeting_div").css('display','none');
         }
         $('#call_forward_call_forwarding_destination').change(function(){
            if($(this).val() == ":PhoneNumber"){
                $("#destination_phone_number").attr('name', 'call_forward[destination]');
                $("#destination_greeting").attr('name', 'disabled');
                $("#destination_phone_number_div").css('display','block');
                $("#destination_greeting_div").css('display','none');
            }
            else if ($('#call_forward_call_forwarding_destination').val().match(voicemail_pattern)){
                $("#destination_phone_number").attr('name', 'disabled');
                $("#destination_greeting").attr('name', 'call_forward[destination]');
                $("#destination_phone_number_div").css('display','none');
                $("#destination_greeting_div").css('display','block');
            } 
            else{
                $("#destination_phone_number").attr('name', 'disabled');
                $("#destination_greeting").attr('name', 'disabled');
                $("#destination_phone_number_div").css('display','none');
                $("#destination_greeting_div").css('display','none');
            }
        })
    }
  });
