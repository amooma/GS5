class AddMarkReadToVoicemailPrefs < ActiveRecord::Migration
  def change
    add_column :voicemail_prefs, :mark_read, :boolean

  end
end
