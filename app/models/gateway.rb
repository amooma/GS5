class Gateway < ActiveRecord::Base
  TECHNOLOGIES = ['sip']

  attr_accessible :name, :technology, :inbound, :outbound, :description

  has_many :gateway_settings, :dependent => :destroy
  has_many :gateway_parameters, :dependent => :destroy

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :technology,
            :presence => true,
            :inclusion => { :in => TECHNOLOGIES }

  before_validation :downcase_technology

  def to_s
    name
  end

  private
  def downcase_technology
    technology = technology.downcase if !technology.blank?
  end

end
