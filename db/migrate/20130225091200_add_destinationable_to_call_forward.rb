class AddDestinationableToCallForward < ActiveRecord::Migration
  def up
    add_column :call_forwards, :destinationable_type, :string
    add_column :call_forwards, :destinationable_id, :integer

    CallForward.all.each do |call_forward|
      call_forward.update_attributes(:destinationable_type => call_forward.call_forwardable_type, :destinationable_id => call_forward.call_forwardable_id, :call_forwardable_type => 'PhoneNumber', :call_forwardable_id => call_forward.phone_number_id )
    end

    remove_column :call_forwards, :phone_number_id
  end

  def down
    add_column :call_forwards, :phone_number_id, :integer
    CallForward.where(:call_forwardable_type => 'PhoneNumber').each do |call_forward|
      call_forward.update_attributes(:phone_number_id => call_forward.call_forwardable_id, :call_forwardable_type => call_forward.destinationable_type, :call_forwardable_id => call_forward.destinationable_id)
    end
    remove_column :call_forwards, :destinationable_type
    remove_column :call_forwards, :destinationable_id
  end
end
