class AreaCode < ActiveRecord::Base
  
  # Associations:
  #
  belongs_to :country
  
  # Validations:
  #
  validates_presence_of :country
  validates_presence_of :name
  validates_presence_of :area_code
  
  validates_uniqueness_of :area_code, :scope => [ :country_id, :central_office_code ]
  
  
  def to_s
    "#{self.name} (#{self.area_code}" +
      (self.central_office_code.blank? ? '' : "-#{self.central_office_code}") +
      ')'
  end
  
end
