class PhoneNumberRange < ActiveRecord::Base
  attr_accessible :name, :description

  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy
  belongs_to :phone_number_rangeable, :polymorphic => true
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:phone_number_rangeable_id, :phone_number_rangeable_type]
  validates_inclusion_of :name, :in => [GsParameter.get('INTERNAL_EXTENSIONS'), GsParameter.get('DIRECT_INWARD_DIALING_NUMBERS'), GsParameter.get('SERVICE_NUMBERS')]
  validates_presence_of :phone_number_rangeable_id
  validates_presence_of :phone_number_rangeable
  
  def to_s
    name
  end
end
