class AcdAgent < ActiveRecord::Base
  DESTINATION_TYPES = ['SipAccount']
  STATUSES = ['active', 'inactive']
  
  attr_accessible :uuid, :name, :status, :automatic_call_distributor_id, :last_call, :calls_answered, :destination_type, :destination_id

  belongs_to :automatic_call_distributor
  
  belongs_to :destination, :polymorphic => true

  after_save :set_presence

  # Validations:
  #
  validates_presence_of :name
  validates_presence_of :destination
  validates_presence_of :destination_id

  def to_s
    self.name || I18n.t('acd_agents.name') + ' ID ' + self.id.to_s
  end

  def toggle_status
    if self.status == 'active'
      self.status = 'inactive'
    else
      self.status = 'active'
    end
    return self.save
  end

  private
  def set_presence
    dialplan_function = nil
    
    state = 'early'
    if self.status == 'active'
      state = 'confirmed'
    elsif self.status == 'inactive'
      state = 'terminated'
    end
      
    require 'freeswitch_event'
    event = FreeswitchEvent.new("PRESENCE_IN")
    event.add_header("proto", "sip")
    event.add_header("from", "f-acdmtg-#{self.id}@#{SipDomain.first.host}")
    event.add_header("event_type", "presence")
    event.add_header("alt_event_type", "dialog")
    event.add_header("presence-call-direction", "outbound")
    event.add_header("answer-state",  state)
    event.add_header("unique-id", "acd_agent_#{self.id}")
    return event.fire()
  end
end
