# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tenant do
    sequence(:name) { |n| "Tenant #{n}" }
    association :country
    association :language
  end
end
