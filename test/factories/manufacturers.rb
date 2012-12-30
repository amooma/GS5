# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :manufacturer do
    sequence(:name) { |n| "#{n}. manufacturer" }
    sequence(:ieee_name) { |n| "#{n}. ieee" }
  end
end