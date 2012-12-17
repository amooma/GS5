class OpenstagePhones < ActiveRecord::Migration
  def up
    siemens = Manufacturer.find_or_create_by_ieee_name('Siemens Enterprise CommunicationsGmbH & Co. KG',
                                                        :name => 'Siemens Enterprise Communications',
                                                        :homepage_url => 'http://www.siemens-enterprise.com')
    
    siemens.phone_models.find_or_create_by_name('Openstage 40',
                                                :product_homepage_url => 'http://www.siemens-enterprise.com/de/products/devices-and-clients/open-stage-desktop-phones.aspx',
                                                :product_manual_homepage_url => 'http://www.siemens-enterprise.com/de/support/downloads-phones-devices/~/media/BOL%20Documents/BOL%20Internet/1%20DownloadFile_P31003S2000U120010019@NETINFO.ashx')
    
    siemens.phone_models.find_or_create_by_name('Openstage 60',
                                                :product_homepage_url => 'http://www.siemens-enterprise.com/de/products/devices-and-clients/open-stage-desktop-phones.aspx',
                                                :product_manual_homepage_url => 'http://www.siemens-enterprise.com/de/support/downloads-phones-devices/~/media/BOL%20Documents/BOL%20Internet/1%20DownloadFile_P31003S2000U119010019@NETINFO.ashx')
    
    
    siemens.phone_models.find_or_create_by_name('Openstage 80',
                                                :product_homepage_url => 'http://www.siemens-enterprise.com/de/products/devices-and-clients/open-stage-desktop-phones.aspx',
                                                :product_manual_homepage_url => 'http://www.siemens-enterprise.com/de/support/downloads-phones-devices/~/media/BOL%20Documents/BOL%20Internet/1%20DownloadFile_P31003S2000U119010019@NETINFO.ashx')
  end

  def down
    siemens = Manufacturer.find_by_ieee_name('Siemens Enterprise CommunicationsGmbH & Co. KG')
    siemens.destroy
  end
end
