class GemeinschaftSetup < ActiveRecord::Base
  belongs_to :user
  accepts_nested_attributes_for :user
  belongs_to :sip_domain
  accepts_nested_attributes_for :sip_domain
  belongs_to :country
  belongs_to :language
end
