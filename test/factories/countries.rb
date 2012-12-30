# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    sequence(:country_code) { |n| "#{n}" }
    sequence(:international_call_prefix) { |n| "#{n}" }
    sequence(:trunk_prefix) { |n| "#{n}" }
  end
end