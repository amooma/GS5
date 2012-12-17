# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :tenant do |f|
  f.sequence(:name) { |n| "Tenant #{n}" }
  f.association :country
  f.association :language
#  f.association :sip_domain
end
