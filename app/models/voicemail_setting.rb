class VoicemailSetting < ActiveRecord::Base  
  CLASS_TYPES = ['String', 'Integer', 'Boolean']
  VOICEMAIL_SETTINGS = {
    'pin'                  => { :type => 'String', :characters => /[^0-9]/, :html => { maxlength: 8 } },
    'notify'               => { :type => 'Boolean', :input =>  :boolean },
    'attachment'           => { :type => 'Boolean', :input =>  :boolean },
    'mark_read'            => { :type => 'Boolean', :input =>  :boolean },
    'purge'                => { :type => 'Boolean', :input =>  :boolean },
    'record_length_max'    => { :type => 'Integer', :input =>  :integer, :html => { min: 0, max: 100 } },
    'record_length_min'    => { :type => 'Integer', :input =>  :integer, :html => { min: 0, max: 100 } },
    'records_max'          => { :type => 'Integer', :input =>  :integer, :html => { min: 0, max: 100 } },
    'pin_length_max'       => { :type => 'Integer', :input =>  :integer, :html => { min: 1, max: 10 } },
    'pin_length_min'       => { :type => 'Integer', :input =>  :integer, :html => { min: 1, max: 8 } },
    'pin_timeout'          => { :type => 'Integer', :input =>  :integer, :html => { min: 1, max: 10 } },
    'key_new_messages'     => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_saved_messages'   => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_config_menu'      => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_terminator'       => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_previous'         => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_next'             => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_delete'           => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_save'             => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'key_main_menu'        => { :type => 'String',  :characters => /[^0-9]\#\*/, :html => { maxlength: 1 } },
    'silence_lenght_abort' => { :type => 'Integer', :input =>  :integer, :html => { min: 0, max: 100 }  },
    'silence_level'        => { :type => 'Integer', :input =>  :integer, :html => { min: 0, max: 1000 } },
    'record_file_prefix'   => { :type => 'String' },
    'record_file_suffix'   => { :type => 'String' },
    'record_file_path'     => { :type => 'String' },
    'record_repeat'        => { :type => 'Integer', :input =>  :integer, :html => { min: 0, max: 10 } },
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
