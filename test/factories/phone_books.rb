# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :phone_book do |f|
  f.sequence(:name) { |n| "Phone book #{n}" }
  f.association :phone_bookable, :factory => :user 
end
