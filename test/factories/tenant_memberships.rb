# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :tenant_membership do |f|
  f.association :user
  f.association :tenant
end