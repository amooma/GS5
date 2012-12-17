class AddSendVoicemailAsEmailAttachmentToUser < ActiveRecord::Migration
  def change
    add_column :users, :send_voicemail_as_email_attachment, :boolean

  end
end
