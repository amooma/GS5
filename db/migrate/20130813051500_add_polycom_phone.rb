class AddPolycomPhone < ActiveRecord::Migration
  def up
    Manufacturer.create(:name => 'Polycom', :ieee_name => 'Polycom', :homepage_url => 'http://www.polycom.com')
    polycom = Manufacturer.where(:name => 'Polycom').first
    if polycom
        polycom.phone_models.create(:name => 'Polycom SoundPoint IP 670', :product_manual_homepage_url => 'http://www.polycom.com/global/documents/support/user/products/voice/SoundPoint_IP_670_User_Guide_SIP_v3_2.pdf', :product_homepage_url => 'http://www.polycom.com/products-services/voice/desktop-solutions/soundpont-ip-series/soundpoint-ip-670.html')
    end
  end

  def down
    Manufacturer.where(:name => 'Polycom').destroy_all
    PhoneModel.where(:name => 'Polycom SoundPoint IP 670').destroy_all
  end
end
