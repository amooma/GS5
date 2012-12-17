class AddHuntGroupFunctionKey < ActiveRecord::Migration
  def up
    softkey_function = SoftkeyFunction.find_or_create_by_name('hunt_group_membership')
    gui_function = GuiFunction.find_or_create_by_name("softkey_function_#{softkey_function.name.downcase}_field_in_softkey_form",
                                                      :category => 'Softkey edit view', 
                                                      :description => "Show the softkey function '#{softkey_function.name}' in the softkey form.")
  end

  def down
    softkey_function = SoftkeyFunction.find_by_name('hunt_group_membership')
    softkey_function.destroy
    GuiFunction.find_by_name("softkey_function_#{softkey_function.name.downcase}_field_in_softkey_form").destroy
  end
end
