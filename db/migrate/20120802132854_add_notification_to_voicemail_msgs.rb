class AddNotificationToVoicemailMsgs < ActiveRecord::Migration
  def change
    add_column :voicemail_msgs, :notification, :boolean

  end
end
