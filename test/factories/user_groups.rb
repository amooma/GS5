# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_group do
    sequence(:name) { |n| "UserGroup #{n}" }
    association :tenant
  end
end