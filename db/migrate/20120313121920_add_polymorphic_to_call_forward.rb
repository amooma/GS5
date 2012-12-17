class AddPolymorphicToCallForward < ActiveRecord::Migration
  def change
    add_column :call_forwards, :call_forwardable_type, :string
    add_column :call_forwards, :call_forwardable_id, :integer

    remove_column :call_forwards, :hunt_group_id
    remove_column :call_forwards, :to_voicemail
  end
end
