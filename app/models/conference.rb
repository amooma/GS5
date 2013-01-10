class Conference < ActiveRecord::Base
  attr_accessible :name, :start, :end, :description, :pin, 
                  :open_for_anybody, :max_members, :announce_new_member_by_name,
                  :announce_left_member_by_name
  
  belongs_to :conferenceable, :polymorphic => true, :touch => true
  has_many :conference_invitees, :dependent => :destroy
  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy

  validates_presence_of  :conferenceable_type, :conferenceable_id
  validates_presence_of  :conferenceable
  validates_presence_of  :name
  validates_presence_of  :start, :if => Proc.new { |conference| !conference.end.blank? }
  validates_presence_of  :end, :if => Proc.new { |conference| !conference.start.blank? }
  validates_presence_of  :max_members
  validates_numericality_of :max_members, :only_integer => true, 
                                          :greater_than => 0,
                                          :less_than => ((GsParameter.get('MAXIMUM_NUMBER_OF_PEOPLE_IN_A_CONFERENCE').nil? ? 10 : GsParameter.get('MAXIMUM_NUMBER_OF_PEOPLE_IN_A_CONFERENCE')) + 1),
                                          :allow_nil => false,
                                          :allow_blank => false

  validates_inclusion_of :open_for_anybody, :in => [true, false]
  
  validates_numericality_of :pin, :only_integer => true, 
                                  :greater_than => 0,
                                  :allow_nil => true,
                                  :allow_blank => true
  validates_length_of       :pin, :minimum => (GsParameter.get('MINIMUM_PIN_LENGTH').nil? ? 4 : GsParameter.get('MINIMUM_PIN_LENGTH')),
                                  :allow_nil => true,
                                  :allow_blank => true
  
  validate :start_and_end_dates_must_make_sense, :if => Proc.new { |conference| !conference.start.blank? && !conference.end.blank? }
  
  after_save :send_pin_email_when_pin_has_changed

  default_scope where(:state => 'active').order(:start)
  
  # State Machine stuff
  state_machine :initial => :active do
  end
  
  def sip_domain
    self.conferenceable.try(:sip_domain)
  end
  
  def to_s
    name
  end
  
  private
  
  def start_and_end_dates_must_make_sense
    errors.add(:start, 'must be in the future') if self.start < Time.now - 10.minutes
    errors.add(:end, 'must be later than the start') if self.end < self.start
  end

  def send_pin_email_when_pin_has_changed
    if self.conferenceable.class == User && self.pin_changed?
      Notifications.new_pin(self).deliver
    end
  end

end
