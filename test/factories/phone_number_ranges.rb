# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :phone_number_range do |f|
  f.name INTERNAL_EXTENSIONS
  f.association :phone_number_rangeable, :factory => :tenant
end
