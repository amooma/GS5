# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :oui do
    association :manufacturer
    sequence(:value) { |n| (n + 11184810).to_s(16).upcase }
  end
end