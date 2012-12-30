# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phone_number do
    sequence(:name) { |n| "Name #{n}" }
    sequence(:number) { |n| "(0)30 227 #{n}" }
    association :phone_numberable, :factory => :phone_book_entry 
  end
end