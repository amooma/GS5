class GemeinschaftSetup < ActiveRecord::Base
  belongs_to :user
  accepts_nested_attributes_for :user
  belongs_to :sip_domain
  accepts_nested_attributes_for :sip_domain
  belongs_to :country
  belongs_to :language

  validates :default_company_name,
            :presence => true,
            :uniqueness => true

  validates :default_system_email,
            :presence => true,
            :uniqueness => true
            
  # Remove the cache which was created by the heater rake task.
  #
  after_create :expire_cache

  before_validation :format_default_area_code

  def detect_attacks
    if self[:detect_attacks] == nil
      return true
    end
    return self[:detect_attacks]
  end

  def detect_attacks=(value)
    self[:detect_attacks] = value
  end

  def report_attacks
    if self[:report_attacks] == nil
      return true
    end
    return self[:report_attacks]
  end

  def report_attacks=(value)
    self[:report_attacks] = value
  end

  private
  def expire_cache
    ActionController::Base.expire_page(Rails.application.routes.url_helpers.new_gemeinschaft_setup_path)
  end

  def format_default_area_code
    if self.default_area_code.blank?
      self.default_area_code = nil
    else
      if self.country != nil && !self.country.trunk_prefix.blank?
        self.default_area_code.gsub(/^#{self.country.trunk_prefix}/,'')
      end
    end
  end
end
