class AddAttachmentToVoicemailPrefs < ActiveRecord::Migration
  def change
    add_column :voicemail_prefs, :attachment, :boolean

  end
end
