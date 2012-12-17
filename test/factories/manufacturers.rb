# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :manufacturer do |f|
  f.sequence(:name) { |n| "#{n}. manufacturer" }
  f.sequence(:ieee_name) { |n| "#{n}. ieee" }
end