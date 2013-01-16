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

  private
  def expire_cache
    ActionController::Base.expire_page(Rails.application.routes.url_helpers.new_gemeinschaft_setup_path)
  end
end
