# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :user_group do |f|
  f.sequence(:name) { |n| "UserGroup #{n}" }
  f.association :tenant
end