class VoicemailAccount < ActiveRecord::Base
  attr_accessible :uuid, :name, :active, :gs_node_id, :voicemail_accountable_type, :voicemail_accountable_id

  belongs_to :voicemail_accountable, :polymorphic => true
  has_many :voicemail_settings
  has_many :voicemail_messages, :foreign_key => 'username', :primary_key => 'name'

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :voicemail_accountable_id,
            :presence => true

  validates :voicemail_accountable_type,
            :presence => true

  def to_s
    "#{voicemail_accountable.to_s}: #{name}"
  end

  def notify_to
    send_notification = nil
    if self.voicemail_settings.where(:name => 'notify', :value => true).first 
      send_notification = true
    elsif self.voicemail_settings.where(:name => 'notify', :value => false).first 
      send_notification = false
    end

    if send_notification == nil
      send_notification = GsParameter.get('notify', 'voicemail', 'settings')
    end

    if !send_notification
      return send_notification
    end

    email = self.voicemail_settings.where(:name => 'email').first.try(:value) 

    if email.blank?
      if self.voicemail_accountable.class == User
        email = self.voicemail_accountable.email
      end
    end

    return email
  end


  def notification_setting(name)
    setting = nil
    if self.voicemail_settings.where(:name => name, :value => true).first 
      setting = true
    elsif self.voicemail_settings.where(:name => name, :value => false).first 
      setting = false
    end

    if setting == nil
      setting = GsParameter.get(name, 'voicemail', 'settings')
    end

    return setting
  end
end
