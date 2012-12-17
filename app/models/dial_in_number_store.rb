class DialInNumberStore < ActiveRecord::Base
  # Associations and Validations
  #
  validates_presence_of :dial_in_number_storeable_type
  validates_presence_of :dial_in_number_storeable_id

  belongs_to :dial_in_number_storeable, :polymorphic => true

  validates_presence_of :dial_in_number_storeable

  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy

  # Delegations:
  #
  delegate :tenant, :to => :dial_in_number_storeable, :allow_nil => true
end
