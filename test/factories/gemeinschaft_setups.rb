# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :gemeinschaft_setup do
    association :user
    association :sip_domain
    association :country
    association :language
  end
end