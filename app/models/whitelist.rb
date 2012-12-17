class Whitelist < ActiveRecord::Base
  attr_accessible :name, :phone_numbers_attributes, :uuid

  belongs_to :whitelistable, :polymorphic => true
  
  # These are the phone_numbers for this whitelist.
  #
  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy

  accepts_nested_attributes_for :phone_numbers, 
                                :reject_if => lambda { |phone_number| phone_number[:number].blank? }, 
                                :allow_destroy => true

  acts_as_list :scope => [ :whitelistable_type, :whitelistable_id ]

  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  def to_s
    self.name || I18n.t('whitelists.name') + ' ID ' + self.id.to_s
  end

end
