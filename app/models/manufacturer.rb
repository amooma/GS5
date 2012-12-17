class Manufacturer < ActiveRecord::Base
  attr_accessible :name, :ieee_name, :homepage_url
  
  # Associations:
  #
  has_many :ouis, :dependent => :destroy
  has_many :phone_models, :order => :name, :dependent => :destroy
  
  
  # Validations:
  #
  validates_presence_of :name
  validates_presence_of :ieee_name
  
  validates_uniqueness_of :name, :case_sensitive => false
  
  validate :validate_homepage_url
  
  # State Machine stuff
  default_scope where(:state => 'active').order(:name)
  state_machine :initial => :active do

    event :deactivate do
      transition [:active] => :deactivated
    end
    
    event :activate do
      transition [:deactivated] => :active
    end
  end
  
  def to_s
    self.name
  end
  
  private
  
  def validate_homepage_url
    if ! self.homepage_url.blank?
      if ! CustomValidators.validate_url( self.homepage_url )
        errors.add( :homepage_url, "is invalid." )
      end
    end
  end
  
end
