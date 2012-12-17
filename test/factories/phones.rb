# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :phone do |f|
  f.sequence(:mac_address) { |n| ('%06d' % n).to_s + ('%06d' % n).to_s }
  f.association :phone_model
  f.association :phoneable, :factory => :tenant 

  # We have to make sure that the OUI is created as well.  
  f.after_build do |instance|
    Factory.create(:oui,
      :manufacturer => instance.phone_model.manufacturer,
      :value        => instance.mac_address.slice(0, 6)
    )
  end
end