# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phone_book_entry do
    sequence(:last_name) { |n| "Lastname #{n}" }
    sequence(:is_male) { |n| true }
    association :phone_book
  end
end
