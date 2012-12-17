# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :sip_domain do |f|
  f.sequence(:host  ) {|n| "host#{n}.localdomain" }
  f.sequence(:realm ) {|n| "host#{n}.localdomain" }
end
