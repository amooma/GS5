class CallForward < ActiveRecord::Base

  attr_accessor :to_voicemail, :hunt_group_id

  attr_accessible :phone_number_id, :call_forward_case_id, :timeout, 
                  :destination, :source, :depth, :active, :to_voicemail,
                  :hunt_group_id,
                  :call_forwardable_type, :call_forwardable_id,
                  :call_forwarding_destination, :position, :uuid
  
  belongs_to :phone_number
  belongs_to :call_forwardable, :polymorphic => true
  has_many :softkeys
  
  acts_as_list :scope => [ :phone_number_id, :call_forward_case_id ]

  validates_presence_of :phone_number
  validates_presence_of :call_forward_case_id
  validates_presence_of :destination, :if => Proc.new { |cf| cf.call_forwardable_type.to_s.downcase == 'phonenumber' || cf.call_forwardable_type.blank?  }

  validates_inclusion_of :destination,
    :in => [ nil, '' ],
    :if => Proc.new { |cf| cf.to_voicemail == true }
  
  belongs_to :call_forward_case

  validates_presence_of      :depth
  validates_numericality_of  :depth,
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

  validate :validate_empty_hunt_group, :if => Proc.new { |cf| cf.active == true && cf.call_forwardable_type == 'HuntGroup' && cf.call_forward_case.value == 'assistant' }
  
  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  # Make sure the call forward's parent can't be changed:
  before_validation { |cfwd|
    if cfwd.id \
    && cfwd.phone_number_id != cfwd.phone_number_id_was
      errors.add( :phone_number_id, "cannot be changed." )
    end
  }

  #before_validation :set_call_forwardable
  before_save :split_and_format_destination_numbers
  after_save :set_presence
  after_save :work_through_callforward_rules_act_per_sip_account
  after_save :deactivate_concurring_entries, :if => Proc.new { |cf| cf.active == true }
  before_destroy :check_if_other_callforward_rules_have_to_be_destroyed
  before_destroy :deactivate_connected_softkeys

  def case_string
    return self.call_forward_case ? self.call_forward_case.value : nil
  end

  def to_s
    if self.call_forwardable_type.blank?
      self.call_forwardable_type = ''
    else
      call_forwardable_type = " #{self.call_forwardable_type}"
    end
    if self.call_forwardable
      destination = "#{self.call_forwardable}#{call_forwardable_type}"
    else
      destination = "#{self.destination}#{call_forwardable_type}"
    end
    "#{self.phone_number} (#{I18n.t("call_forward_cases.#{self.call_forward_case}")}) -> #{destination}"
  end

  def set_this_callforward_rule_to_all_phone_numbers_of_the_parent_sip_account
    # This is to make sure that no recursion kicks in.
    #
    if ! self.phone_number.phone_numberable.respond_to? :callforward_rules_act_per_sip_account
      return false
    end

    old_value_of_callforward_rules_act_per_sip_account = self.phone_number.phone_numberable.callforward_rules_act_per_sip_account
    self.phone_number.phone_numberable.update_attributes({:callforward_rules_act_per_sip_account => false})

    attributes_of_this_call_forward = self.attributes.delete_if {|key, value| ['id','updated_at','created_at','phone_number_id','call_forward_case_id', 'uuid'].include?(key)}
    phone_numbers = self.phone_number.phone_numberable.phone_numbers.where('id != ?', self.phone_number.id)

    phone_numbers.each do |phone_number|
      # Problem
      call_forward = phone_number.call_forwards.find_or_create_by_call_forward_case_id_and_position(self.call_forward_case_id, self.position, attributes_of_this_call_forward)
      call_forward.update_attributes(attributes_of_this_call_forward)
    end

    self.phone_number.phone_numberable.update_attributes({:callforward_rules_act_per_sip_account => old_value_of_callforward_rules_act_per_sip_account})
  end

  def destroy_all_similar_callforward_rules_of_the_parent_sip_account
    # This is to make sure that no recursion kicks in.
    #
    if ! self.phone_number.phone_numberable.respond_to? :callforward_rules_act_per_sip_account
      return false
    end

    old_value_of_callforward_rules_act_per_sip_account = self.phone_number.phone_numberable.callforward_rules_act_per_sip_account
    self.phone_number.phone_numberable.update_attributes({:callforward_rules_act_per_sip_account => false})

    phone_numbers_of_parent_sip_account = self.phone_number.phone_numberable.phone_numbers.where('id != ?', self.phone_number.id)

    phone_numbers_of_parent_sip_account.each do |phone_number|
      if self.call_forwardable_type != 'Voicemail'
        phone_number.call_forwards.where(:call_forward_case_id => self.call_forward_case_id, :destination => self.destination).destroy_all
      else
        phone_number.call_forwards.where(:call_forward_case_id => self.call_forward_case_id, :call_forwardable_type => self.call_forwardable_type).destroy_all
      end
    end

    self.phone_number.phone_numberable.update_attributes({:callforward_rules_act_per_sip_account => old_value_of_callforward_rules_act_per_sip_account})
  end

  def call_forwarding_destination
    "#{self.call_forwardable_id}:#{self.call_forwardable_type}"
  end

  def call_forwarding_destination=(destination_record)
    self.call_forwardable_id, delimeter, self.call_forwardable_type = destination_record.to_s.partition(':')
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
  def split_and_format_destination_numbers
    if !self.destination.blank?
      destinations = self.destination.gsub(/[^+0-9\,]/,'').gsub(/[\,]+/,',').split(/\,/).delete_if{|x| x.blank?}
      self.destination = nil
      if destinations.count > 0
        destinations.each do |single_destination|
          self.destination = self.destination.to_s + ", #{PhoneNumber.parse_and_format(single_destination)}"
        end
      end
      self.destination = self.destination.to_s.gsub(/[^+0-9\,]/,'').gsub(/[\,]+/,',').split(/\,/).sort.delete_if{|x| x.blank?}.join(', ')
    end
  end

  def set_presence
    state = 'terminated'

    if self.active
      if self.call_forwardable_type and self.call_forwardable_type.downcase() == 'voicemail'
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

  def set_call_forwardable
    if @hunt_group_id && HuntGroup.where(:id => @hunt_group_id.to_i).count > 0
      self.call_forwardable = HuntGroup.where(:id => @hunt_group_id.to_i).first
    end

    if @to_voicemail && @to_voicemail.first.downcase == 'true'
      self.call_forwardable_type = 'Voicemail'
      self.call_forwardable_id = nil
    end 
  end

  def work_through_callforward_rules_act_per_sip_account
    if ! self.phone_number.phone_numberable.respond_to? :callforward_rules_act_per_sip_account
      return false
    end

    if self.phone_number.phone_numberable.callforward_rules_act_per_sip_account == true
      self.set_this_callforward_rule_to_all_phone_numbers_of_the_parent_sip_account
    end
  end

  def check_if_other_callforward_rules_have_to_be_destroyed
    if ! self.phone_number.phone_numberable.respond_to? :callforward_rules_act_per_sip_account
      return false
    end

    if self.phone_number.phone_numberable.callforward_rules_act_per_sip_account == true
      self.destroy_all_similar_callforward_rules_of_the_parent_sip_account
    end
  end

  def send_presence_event(state, call_forwarding_service = nil)
    dialplan_function = "cftg-#{self.id}"
    unique_id = "call_forwarding_#{self.id}"

    if call_forwarding_service == 'always'
      dialplan_function = "cfutg-#{self.phone_number.id}"
      unique_id = "call_forwarding_number_#{self.phone_number.id}"
    elsif call_forwarding_service == 'assistant'
      dialplan_function = "cfatg-#{self.phone_number.id}"
      unique_id = "call_forwarding_number_#{self.phone_number.id}"
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
    CallForward.where(:phone_number_id => self.phone_number_id, :call_forward_case_id => self.call_forward_case_id, :active => true).each do |call_forwarding_entry|
      if call_forwarding_entry.id != self.id
        call_forwarding_entry.update_attributes(:active => false)
      end
    end
  end

  def validate_empty_hunt_group
    hunt_group = self.call_forwardable
    if hunt_group && hunt_group.hunt_group_members.where(:active => true).count == 0
      errors.add(:call_forwarding_destination, 'HuntGroup has no active members')
    end
  end
  
end
