class AddGigasetPhone < ActiveRecord::Migration
  def up
    Manufacturer.create(:name => 'Gigaset', :ieee_name => 'Gigaset Communications GmbH', :homepage_url => 'http://www.gigaset.com')
    gigaset = Manufacturer.where(:name => 'Gigaset').first
    if gigaset
        gigaset.phone_models.create(:name => 'Gigaset C610 IP', 
          :product_manual_homepage_url => 'https://www.gigaset.com/fileadmin/legacy-assets/A31008-M2312-R301-1-6019_en_US_CA.pdf',
          :product_homepage_url => 'http://www.gigaset.com/en_HQ/shop/gigaset-c610-ip.html')
        gigaset.phone_models.create(:name => 'Gigaset N510 IP PRO',
          :product_manual_homepage_url => 'https://www.gigaset.com/fileadmin/legacy-assets/A31008-M2217-R101-4-7619_en_UK.pdf',
          :product_homepage_url => 'http://www.gigaset.com/en_HQ/shop/gigaset-n510-ip-pro.html')
    end
  end

  def down
    PhoneModel.where(:name => 'Gigaset C610 IP').destroy_all
    PhoneModel.where(:name => 'Gigaset N510 IP PRO').destroy_all
    Manufacturer.where(:name => 'Gigaset').destroy_all
  end
end
