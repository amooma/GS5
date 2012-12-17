class Country < ActiveRecord::Base
  
  has_many :area_codes, :dependent => :destroy
  has_many :tenants
  has_many :phone_number_ranges, :as => :phone_number_rangeable, :dependent => :destroy
  
  validates_presence_of :name
  validates_presence_of :country_code
  validates_presence_of :international_call_prefix

  validates_numericality_of :country_code,
    :only_integer => true
  
  validates_uniqueness_of :name, :scope => [ :country_code ],
    :case_sensitive => false
  
  def to_s
    self.name
  end
  
end
