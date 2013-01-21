class GemeinschaftSetup < ActiveRecord::Base
  belongs_to :user
  accepts_nested_attributes_for :user
  belongs_to :sip_domain
  accepts_nested_attributes_for :sip_domain
  belongs_to :country
  belongs_to :language

  # Remove the cache which was created by the heater rake task.
  #
  after_create :expire_cache

  before_validation :format_default_area_code

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
