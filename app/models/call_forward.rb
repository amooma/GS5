class CallForward < ActiveRecord::Base

  attr_accessor :to_voicemail, :hunt_group_id

  attr_accessible :call_forward_case_id, :timeout, 
                  :destination, :source, :depth, :active, :to_voicemail,
                  :hunt_group_id,
                  :call_forwardable_type, :call_forwardable_id,
                  :call_forwarding_destination, :position, :uuid,
                  :destinationable_type, :destinationable_id
  
  belongs_to :call_forwardable, :polymorphic => true
  belongs_to :destinationable, :polymorphic => true
  has_many :softkeys, :as => :softkeyable
  
  acts_as_list :scope => [ :call_forwardable_id, :call_forwardable_type, :call_forward_case_id ]

  validates_presence_of :call_forward_case_id
  validates_presence_of :destination, :if => Proc.new { |cf| cf.destinationable_type.to_s.downcase == 'phonenumber' || cf.destinationable_type.blank?  }

  validates_inclusion_of :destination,
    :in => [ nil, '' ],
    :if => Proc.new { |cf| cf.to_voicemail == true }
  
  belongs_to :call_forward_case

  validates_numericality_of  :depth,
    :allow_nil => true,
    :only_integer => true,
    :greater_than_or_equal_to  =>   1,
    :less_than_or_equal_to     =>  (GsParameter.get('MAX_CALL_FORWARD_DEPTH').nil? ? 0 : GsParameter.get('MAX_CALL_FORWARD_DEPTH'))
  
  before_validation {
    self.timeout = nil if self.call_forward_case_id != 3
  }

  validates_numericality_of :timeout,
    :if => Proc.new { |cf| cf.call_forward_case_id == 3 },
    :only_integer => true,
    :greater_than_or_equal_to  =>   1,
    :less_than_or_equal_to     => 120
  
  validates_inclusion_of :timeout,
    :in => [ nil ],
    :if => Proc.new { |cf| cf.call_forward_case_id != 3 }

  validate :validate_empty_hunt_group, :if => Proc.new { |cf| cf.active == true && cf.destinationable_type == 'HuntGroup' && cf.call_forward_case.value == 'assistant' }
  
  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  # Make sure the call forward's parent can't be changed:
  before_validation { |cfwd|
    if cfwd.id && (cfwd.call_forwardable_id != cfwd.call_forwardable_id_was || cfwd.call_forwardable_type != cfwd.call_forwardable_type_was)
      errors.add( :call_forwardable_id, "cannot be changed." )
    end
  }

  before_validation :resolve_prerouting

  after_save :set_presence
  after_save :deactivate_concurring_entries, :if => Proc.new { |cf| cf.active == true }
  before_destroy :deactivate_connected_softkeys

  def case_string
    return self.call_forward_case ? self.call_forward_case.value : nil
  end

  def to_s
    if self.destinationable_type.blank?
      self.destinationable_type = ''
    else
      destinationable_type = " #{self.destinationable_type}"
    end
    if Module.constants.include?(destinationable_type.to_sym) && self.destinationable
      destination = "#{self.destinationable}#{destinationable_type}"
    else
      destination = "#{self.destination}#{destinationable_type}"
    end
    "#{self.call_forwardable} (#{I18n.t("call_forward_cases.#{self.call_forward_case}")}) -> #{destination}"
  end

  def call_forwarding_destination
    "#{self.destinationable_id}:#{self.destinationable_type}"
  end

  def call_forwarding_destination=(destination_record)
    self.destinationable_id, delimeter, self.destinationable_type = destination_record.to_s.partition(':')
  end

  def toggle
    self.active = ! self.active
    return self.save
  end

  def deactivate_connected_softkeys
    softkey_function_deactivated = SoftkeyFunction.find_by_name('deactivated')
    self.softkeys.each do |softkey|
      if softkey.softkey_function_id != softkey_function_deactivated.id
        softkey.update_attributes(:softkeyable_id => nil, :softkeyable_type => nil, :softkey_function_id => softkey_function_deactivated.id)
      end
    end
  end

  private
  def set_presence
    state = 'terminated'

    if self.active
      if self.destinationable_type and self.destinationable_type.downcase() == 'voicemail'
        state = 'early'
      else
        state = 'confirmed'
      end
    end

    return send_presence_event(state)

    #if self.call_forward_case_id_changed?
    #  call_forwarding_service = CallForwardCase.where(:id => self.call_forward_case_id_was).first
    #  if call_forwarding_service
    #    send_presence_event(call_forwarding_service.value, state)
    #  end
    #end

    #return send_presence_event(self.call_forward_case.value, state)
  end

  def set_destinationable
    if @hunt_group_id && HuntGroup.where(:id => @hunt_group_id.to_i).count > 0
      self.destinationable = HuntGroup.where(:id => @hunt_group_id.to_i).first
    end

    if @to_voicemail && @to_voicemail.first.downcase == 'true'
      self.destinationable_type = 'Voicemail'
      self.destinationable_id = nil
    end 
  end

  def resolve_prerouting
    if self.destinationable_type == 'PhoneNumber' && GsParameter.get('CALLFORWARD_DESTINATION_RESOLVE') != false
      if self.call_forwardable.class == PhoneNumber
        prerouting = PhoneNumber.resolve_prerouting(self.destination, self.call_forwardable.phone_numberable)
      else
        prerouting = PhoneNumber.resolve_prerouting(self.destination, self.call_forwardable)
      end
      if prerouting && !prerouting['destination_number'].blank? && prerouting['type'] == 'phonenumber'
        self.destination = prerouting['destination_number']
      end
    end
  end

  def send_presence_event(state, call_forwarding_service = nil)
    dialplan_function = "cftg-#{self.id}"
    unique_id = "call_forwarding_#{self.id}"

    if call_forwarding_service == 'always'
      dialplan_function = "cfutg-#{self.call_forwardable.id}"
      unique_id = "call_forwarding_number_#{self.call_forwardable.id}"
    elsif call_forwarding_service == 'assistant'
      dialplan_function = "cfatg-#{self.call_forwardable.id}"
      unique_id = "call_forwarding_number_#{self.call_forwardable.id}"
    end

    if dialplan_function
      require 'freeswitch_event'
      event = FreeswitchEvent.new("PRESENCE_IN")
      event.add_header("proto", "sip")
      event.add_header("from", "f-#{dialplan_function}@#{SipDomain.first.host}")
      event.add_header("event_type", "presence")
      event.add_header("alt_event_type", "dialog")
      event.add_header("presence-call-direction", "outbound")
      event.add_header("answer-state",  state)
      event.add_header("unique-id", unique_id)
      return event.fire()
    end   
  end

  def deactivate_concurring_entries
    CallForward.where(:call_forwardable_id => self.call_forwardable_id, :call_forwardable_type => self.call_forwardable_type, :call_forward_case_id => self.call_forward_case_id, :source => self.source, :active => true).each do |call_forwarding_entry|
      if call_forwarding_entry.id != self.id
        call_forwarding_entry.update_attributes(:active => false)
      end
    end
  end

  def validate_empty_hunt_group
    hunt_group = self.destinationable
    if hunt_group && hunt_group.hunt_group_members.where(:active => true).count == 0
      errors.add(:call_forwarding_destination, 'HuntGroup has no active members')
    end
  end
  
end
