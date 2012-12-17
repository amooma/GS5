# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :phone_number do |f|
  f.sequence(:name) { |n| "Name #{n}" }
  f.sequence(:number) { |n| "(0)30 227 #{n}" }
  f.association :phone_numberable, :factory => :phone_book_entry 
end