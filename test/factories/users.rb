# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do 
	factory :user do
    sequence(:user_name) { |n| "User #{n}" }
    sequence(:first_name) { |n| "John #{n}" }
    sequence(:last_name) { |n| "Smith #{n}" }
    sequence(:email) { |n| "john.smith#{n}@company.com" }
    sequence(:password) { |n| "Testpassword#{n}" }
    sequence(:password_confirmation) { |n| "Testpassword#{n}" }
    association :language
  end
end