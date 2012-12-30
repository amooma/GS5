# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conference do
    sequence(:name) { |n| "Conference room #{n}" }
    open_for_anybody true
    association :conferenceable, :factory => :tenant 
    max_members 10
  end
end