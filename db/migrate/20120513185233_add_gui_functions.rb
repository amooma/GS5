class AddGuiFunctions < ActiveRecord::Migration
  def up
  	GuiFunction.create(:category => 'Top navigation bar', :name => 'user_avatar_in_top_navigation_bar',
  										 :description => 'Show the user avatar in the top navigaction bar.')
  	GuiFunction.create(:category => 'Top navigation bar', :name => 'search_field_in_top_navigation_bar',
  										 :description => 'Show the search field for phone book entries in the top navigation bar.')
  	GuiFunction.create(:category => 'Top navigation bar', :name => 'navigation_items_in_top_navigation_bar',
  										 :description => 'Show the navigation items in the top navigation bar.')
  	GuiFunction.create(:category => 'User show view', :name => 'show_phone_books_in_user_show_view',
  										 :description => 'Show the available phone books in the user show view.')
  	GuiFunction.create(:category => 'Footer', :name => 'amooma_commercial_support_link_in_footer',
  										 :description => 'Show a link to the AMOOMA commerical support page in the footer.')
  	GuiFunction.create(:category => 'Footer', :name => 'gemeinschaft_mailinglist_link_in_footer',
  										 :description => 'Show a link to the Gemeinschaft Mailinglist in the footer.')
  	GuiFunction.create(:category => 'User edit view', :name => 'name_data_fields_in_user_edit_form',
  										 :description => 'Show gender, first name, middle name, last name in the User edit form.')
  	GuiFunction.create(:category => 'User edit view', :name => 'user_name_field_in_user_edit_form',
  										 :description => 'Show user name (login) field in the User edit form.')
  	GuiFunction.create(:category => 'User edit view', :name => 'email_field_in_user_edit_form',
  										 :description => 'Show e-mail field in the User edit form.')
  	GuiFunction.create(:category => 'User edit view', :name => 'password_fields_in_user_edit_form',
  										 :description => 'Show password fields in the User edit form.')
  	GuiFunction.create(:category => 'User edit view', :name => 'pin_fields_in_user_edit_form',
  										 :description => 'Show PIN fields in the User edit form.')
  	GuiFunction.create(:category => 'Call Forward edit view', :name => 'depth_field_in_call_forward_form',
  										 :description => 'Show depth field in the call forward form.')
  	GuiFunction.create(:category => 'Call Forward index view', :name => 'depth_field_value_in_index_table',
  										 :description => 'Show depth field in the call forwards table.')

    CallForwardCase.all.each do |call_forward_case|
	  	GuiFunction.create(:category => 'Call Forward edit view', :name => "call_forward_case_#{call_forward_case.value.downcase}_field_in_call_forward_form",
	  										 :description => "Show the call forward case '#{call_forward_case.value}' in the forward form.")
    end

  	GuiFunction.create(:category => 'Call Forward edit view', :name => 'huntgroup_in_destination_field_in_call_forward_form',
  										 :description => 'Show huntgroups in the destination field of the call forward form.')

    SoftkeyFunction.all.each do |softkey_function|
	  	GuiFunction.create(:category => 'Softkey edit view', :name => "softkey_function_#{softkey_function.name.downcase}_field_in_softkey_form",
	  										 :description => "Show the softkey function '#{softkey_function.name}' in the softkey form.")
    end
  end

  def down
  	GuiFunction.destroy_all
  end
end
