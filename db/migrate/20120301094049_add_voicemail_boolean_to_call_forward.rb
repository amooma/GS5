class AddVoicemailBooleanToCallForward < ActiveRecord::Migration
  def change
    add_column :call_forwards, :to_voicemail, :boolean

  end
end
