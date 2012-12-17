class HuntGroupMember < ActiveRecord::Base
  attr_accessible :name, :active, :can_switch_status_itself, :phone_numbers_attributes

  belongs_to :hunt_group
  validates_presence_of :hunt_group

  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy
  accepts_nested_attributes_for :phone_numbers, 
                                :reject_if => lambda { |phone_number| phone_number[:number].blank? }, 
                                :allow_destroy => true

  acts_as_list :scope => :hunt_group

  after_save :set_presence
  after_save :trigger_connected_call_forward_if_necessary

  def to_s
	  self.name || I18n.t('hunt_group_members.name') + ' ID ' + self.id.to_s
  end

  private
  def set_presence
    dialplan_function = nil
    state = 'terminated'

    if self.active
      state = 'confirmed'
    end

    require 'freeswitch_event'
    event = FreeswitchEvent.new("PRESENCE_IN")
    event.add_header("proto", "sip")
    event.add_header("from", "f-hgmtg-#{self.id}@#{SipDomain.first.host}")
    event.add_header("event_type", "presence")
    event.add_header("alt_event_type", "dialog")
    event.add_header("presence-call-direction", "outbound")
    event.add_header("answer-state",  state)
    event.add_header("unique-id", "hunt_group_member_#{self.id}")
    return event.fire()
  end

  # Turn on/off a connected CallForward.
  # The last member who leaves the hunt_group deactivates the CallForward and the 
  # first member actives it.
  #
  def trigger_connected_call_forward_if_necessary
    if self.active_changed? && self.hunt_group.hunt_group_members.count > 0
      # deactive CallForward
      #
      if self.hunt_group.hunt_group_members.where(:active => false).count == self.hunt_group.hunt_group_members.count
        self.hunt_group.call_forwards.where(:active => true).each do |x|
          x.update_attributes({:active => false})
        end
      end

      # active CallForward
      #
      if self.hunt_group.hunt_group_members.where(:active => true).count > 0
        self.hunt_group.call_forwards.where(:active => false).each do |x|
          x.update_attributes({:active => true})
        end
      end
    end
  end


end
