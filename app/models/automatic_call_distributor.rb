class AutomaticCallDistributor < ActiveRecord::Base
  attr_accessible :uuid, :name, :strategy, :automatic_call_distributorable_type, :automatic_call_distributorable_id, :max_callers, :agent_timeout, :retry_timeout, :join, :leave, :gs_node_id, :announce_position, :announce_call_agents, :greeting, :goodbye, :music

  belongs_to :automatic_call_distributorable, :polymorphic => true, :touch => true

  has_many :acd_agents, :dependent => :destroy
  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy
  accepts_nested_attributes_for :phone_numbers, 
                                :reject_if => lambda { |phone_number| phone_number[:number].blank? }, 
                                :allow_destroy => true

  validates_presence_of :strategy

  STRATEGIES  = ['ring_all', 'round_robin']
  JOIN_ON = ['agents_available', 'agents_active', 'always']
  LEAVE_ON = ['no_agents_available_timeout', 'no_agents_active_timeout', 'no_agents_available', 'no_agents_active', 'timeout', 'never']

  after_initialize :set_defaults

  def to_s
    self.name
  end

  private
  def set_defaults 
    self.announce_call_agents ||= 'ivr/ivr-stay_on_line_call_answered_momentarily.wav'
    self.greeting ||= 'ivr/ivr-thank_you_for_calling.wav'
    self.goodbye ||= 'ivr/ivr-thank_you_for_calling.wav'
    self.music ||= 'local_stream://mohl'
  end
end
