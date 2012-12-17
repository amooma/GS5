# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :phone_book_entry do |f|
  f.sequence(:last_name) { |n| "Lastname #{n}" }
  f.sequence(:is_male) { |n| true }
  f.association :phone_book
end
