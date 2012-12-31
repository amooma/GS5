# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :phone do |f|
    f.sequence(:mac_address) { |n| ('%06d' % n).to_s + ('%06d' % n).to_s }
    f.association :phone_model
    f.association :phoneable, :factory => :tenant 

    # We have to make sure that the OUI is created as well.  
    f.after_build do |instance|
      FactoryGirl.create(:oui,
        :manufacturer => instance.phone_model.manufacturer,
        :value        => instance.mac_address.slice(0, 6)
      )
    end
  end
end