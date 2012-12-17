class AddPurgeToVoicemailPrefs < ActiveRecord::Migration
  def change
    add_column :voicemail_prefs, :purge, :boolean

  end
end
