# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :country do |f|
  f.sequence(:name) { |n| "Country #{n}" }
  f.sequence(:country_code) { |n| "#{n}" }
  f.sequence(:international_call_prefix) { |n| "#{n}" }
  f.sequence(:trunk_prefix) { |n| "#{n}" }
end