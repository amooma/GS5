# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phone_book do
    sequence(:name) { |n| "Phone book #{n}" }
    association :phone_bookable, :factory => :user 
  end
end
