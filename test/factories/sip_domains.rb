# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sip_domain do
    sequence(:host  ) {|n| "host#{n}.localdomain" }
    sequence(:realm ) {|n| "host#{n}.localdomain" }
  end
end
