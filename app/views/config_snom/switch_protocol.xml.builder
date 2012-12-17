xml.instruct!  # <?xml version="1.0" encoding="UTF-8"?>

xml.settings {
	xml.tag!( 'phone-settings' ) {
		xml.auto_reboot_on_setting_change( 'on', :perm => 'RW' )
		xml.settings_refresh_timer( '60', :perm => 'RW' )
		xml.reset_settings( 'main net stack user fkey speeddial phonebook', :perm => 'RW' )
		#xml.dhcp( 'off', :perm => 'RW' )
		#xml.ip_adr( @ip_address, :perm => 'RW' )
		xml.setting_server( @prov_url, :perm => 'RW' )
	}	
}


# Local Variables:
# mode: ruby
# End:

