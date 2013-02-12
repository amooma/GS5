class AddSoftkeyableToSoftkey < ActiveRecord::Migration
  def up
    add_column :softkeys, :softkeyable_type, :string
    add_column :softkeys, :softkeyable_id, :integer
    Softkey.where('call_forward_id > 0').each do |softkey|
      softkey.update_attributes( :softkeyable_type => 'CallForward', :softkeyable_id => softkey.call_forward_id )
    end
    remove_column :softkeys, :call_forward_id
  end

  def down
    remove_column :softkeys, :softkeyable_type
    remove_column :softkeys, :softkeyable_id
    add_column :softkeys, :call_forward_id, :integer
  end
end
