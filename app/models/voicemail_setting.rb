class VoicemailSetting < ActiveRecord::Base  
  CLASS_TYPES = ['String', 'Integer', 'Boolean']
  VOICEMAIL_SETTINGS = {
    'password'           => { :type => 'String', :characters => /[^0-9]/, :input => :password },
    'notify'             => { :type => 'Boolean', :input =>  :boolean },
    'attachment'         => { :type => 'Boolean', :input =>  :boolean },
    'mark_read'          => { :type => 'Boolean', :input =>  :boolean },
    'purge'              => { :type => 'Boolean', :input =>  :boolean },
    'record_length_max'  => { :type => 'Integer', :input =>  :integer },
    'record_length_min'  => { :type => 'Integer', :input =>  :integer },
    'records_max'        => { :type => 'Integer', :input =>  :integer },
  }

  attr_accessible :voicemail_account_id, :name, :value, :class_type, :description

  belongs_to :voicemail_account

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :voicemail_account_id}

  validates :class_type,
            :presence => true,
            :inclusion => { :in => CLASS_TYPES }

  before_validation :set_class_type_and_value

  def to_s
  	name
  end

  def set_class_type_and_value
    seting_pref = VOICEMAIL_SETTINGS[self.name]
    if seting_pref
      self.class_type = seting_pref[:type]
      case self.class_type
      when 'String'
        if seting_pref[:characters] && self.class_type == 'String'
          self.value = self.value.to_s.gsub(seting_pref[:characters], '')
        end
      when 'Integer'
        self.value = self.value.to_i
      when 'Boolean'
        self.value = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(self.value)
      end
    end
  end
end
