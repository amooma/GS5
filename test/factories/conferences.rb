# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :conference do |f|
  f.sequence(:name) { |n| "Conference room #{n}" }
  f.open_for_anybody true
  f.association :conferenceable, :factory => :tenant 
  f.max_members 10
end