class Gateway < ActiveRecord::Base
  TECHNOLOGIES = ['sip', 'xmpp']

  attr_accessible :name, :technology, :inbound, :outbound, :description

  has_many :gateway_settings, :dependent => :destroy
  has_many :gateway_parameters, :dependent => :destroy

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :technology,
            :presence => true,
            :inclusion => { :in => TECHNOLOGIES }

  after_initialize :set_defaults
  before_validation :downcase_technology

  def to_s
    name
  end

  private
  def downcase_technology
    self.technology = self.technology.downcase if !self.technology.blank?
  end

  def set_defaults 
    if TECHNOLOGIES.count == 1
      self.technology = TECHNOLOGIES.first
    end
  end

end
