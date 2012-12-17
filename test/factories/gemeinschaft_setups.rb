# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :gemeinschaft_setup do |f|
  f.association :user
  f.association :sip_domain
  f.association :country
  f.association :language
end