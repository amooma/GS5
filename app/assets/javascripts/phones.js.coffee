jQuery ->
  $(".fallback_sip_account_dropdown").hide()  

  $("#phone_hot_deskable").change ->
    $(".fallback_sip_account_dropdown").show("slow")
