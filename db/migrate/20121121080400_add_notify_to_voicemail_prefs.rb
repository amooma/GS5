class AddNotifyToVoicemailPrefs < ActiveRecord::Migration
  def change
    add_column :voicemail_prefs, :notify, :boolean

  end
end
