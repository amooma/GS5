class AddPhoneNumberIdToCallForward < ActiveRecord::Migration
  
  def change
    remove_column :call_forwards, :sip_account_id
    add_column    :call_forwards, :phone_number_id, :integer
    add_index( :call_forwards, :phone_number_id )
  end
  
end
