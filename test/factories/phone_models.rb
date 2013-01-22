# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phone_model do
    sequence(:name) { |n| "Phone Model #{n}" }
    association :manufacturer
  end
end
