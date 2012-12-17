# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :user do |f|
  f.sequence(:user_name) { |n| "User #{n}" }
  f.sequence(:first_name) { |n| "John #{n}" }
  f.sequence(:last_name) { |n| "Smith #{n}" }
  f.sequence(:email) { |n| "john.smith#{n}@company.com" }
  f.sequence(:password) { |n| "Testpassword#{n}" }
  f.sequence(:password_confirmation) { |n| "Testpassword#{n}" }
  f.association :language
end