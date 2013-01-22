# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
	factory :area_code do
    sequence(:name) { |n| "AreaCode #{n}" }
    sequence(:area_code) { |n| "#{n}" }
    association :country
  end
end