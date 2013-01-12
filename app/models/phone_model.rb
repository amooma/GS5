class PhoneModel < ActiveRecord::Base
  attr_accessible :name, :product_manual_homepage_url, :product_homepage_url, :uuid
  
  # Associations
  #
  belongs_to :manufacturer, :touch => true
  
  has_many :phones, :dependent => :destroy
  
  # Validations
  #
  validates_presence_of :name
  validate :validate_product_manual_homepage_url
  validate :validate_product_homepage_url

  validates_presence_of :uuid
  validates_uniqueness_of :uuid
  
  def to_s
    self.name
  end
  
  # State machine:
  #
  default_scope where(:state => 'active')
  state_machine :initial => :active do
    
    event :deactivate do
      transition [:active] => :deactivated
    end
    
    event :activate do
      transition [:deactivated] => :active
    end
  end
  
  
  private
  
  def validate_product_manual_homepage_url
    if ! self.product_manual_homepage_url.blank?
      if ! CustomValidators.validate_url( self.product_manual_homepage_url )
        errors.add( :product_manual_homepage_url, "is invalid." )
      end
    end
  end
  
  def validate_product_homepage_url
    if ! self.product_homepage_url.blank?
      if ! CustomValidators.validate_url( self.product_homepage_url )
        errors.add( :product_homepage_url, "is invalid." )
      end
    end
  end
  
end
