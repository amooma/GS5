# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :area_code do |f|
  f.sequence(:name) { |n| "AreaCode #{n}" }
  f.sequence(:area_code) { |n| "#{n}" }
  f.association :country
end