# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :tenant_membership do
    association :user
    association :tenant
  end
end