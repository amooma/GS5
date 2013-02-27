class HuntGroup < ActiveRecord::Base
  attr_accessible :name, :strategy, :seconds_between_jumps, :phone_numbers_attributes

  belongs_to :tenant, :touch => true
  has_many :call_forwards, :as => :destinationable, :dependent => :destroy

  validates_uniqueness_of :name, :scope => :tenant_id,
                                 :allow_nil => true, :allow_blank => true

  validates_presence_of  :strategy
  validates_inclusion_of :strategy, :in => (GsParameter.get('HUNT_GROUP_STRATEGIES').nil? ? [] : GsParameter.get('HUNT_GROUP_STRATEGIES'))

  validates_presence_of     :seconds_between_jumps, 
                            :if => Proc.new{ |hunt_group| hunt_group.strategy != 'ring_all' }
  validates_numericality_of :seconds_between_jumps,
                            :only_integer => true,
                            :greater_than_or_equal_to => (GsParameter.get('VALID_SECONDS_BETWEEN_JUMPS_VALUES').nil? ? 2 : GsParameter.get('VALID_SECONDS_BETWEEN_JUMPS_VALUES').min),
                            :less_than_or_equal_to => (GsParameter.get('VALID_SECONDS_BETWEEN_JUMPS_VALUES').nil? ? 120 : GsParameter.get('VALID_SECONDS_BETWEEN_JUMPS_VALUES').max),
                            :if => Proc.new{ |hunt_group| hunt_group.strategy != 'ring_all' }
  validates_inclusion_of    :seconds_between_jumps, 
                            :in => (GsParameter.get('VALID_SECONDS_BETWEEN_JUMPS_VALUES').nil? ? [] : GsParameter.get('VALID_SECONDS_BETWEEN_JUMPS_VALUES')),
                            :if => Proc.new{ |hunt_group| hunt_group.strategy != 'ring_all' }
  validates_inclusion_of    :seconds_between_jumps,
                            :in => [nil],
                            :if => Proc.new{ |hunt_group| hunt_group.strategy == 'ring_all' }

  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  has_many :hunt_group_members, :dependent => :destroy, :order => :position

  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy
  accepts_nested_attributes_for :phone_numbers, 
                                :reject_if => lambda { |phone_number| phone_number[:number].blank? }, 
                                :allow_destroy => true

  has_many :hunt_group_members, :dependent => :destroy

  def to_s
    self.name || I18n.t('hunt_groups.name') + ' ID ' + self.id.to_s
  end

end
