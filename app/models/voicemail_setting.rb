class VoicemailSetting < ActiveRecord::Base
  self.table_name = 'voicemail_prefs'
  self.primary_key = 'username'

  attr_accessible :username, :domain, :name_path, :greeting_path, :password, :notify, :attachment, :mark_read, :purge, :sip_account

  has_one :sip_account, :foreign_key => 'auth_name'

  validates_presence_of :username
  validates_presence_of :domain
  validates :username, :uniqueness => {:scope => :domain}
end
