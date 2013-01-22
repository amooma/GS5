# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phone_number_range do
    name 'internal_extensions'
    association :phone_number_rangeable, :factory => :tenant
  end
end
