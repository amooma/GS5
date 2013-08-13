class AddYealinkPhone < ActiveRecord::Migration
  def up
    Manufacturer.create(:name => 'Yealink', :ieee_name => 'XIAMEN YEALINK NETWORK TECHNOLOGY CO.,LTD', :homepage_url => 'http://www.yealink.com')
    yealink = Manufacturer.where(:name => 'Yealink').first
    if yealink
        yealink.phone_models.create(:name => 'Yealink W52P', :product_manual_homepage_url => 'http://www.yealink.com/Upload/W52P/V30/Yealink%20W52P_User_Guide_V30.pdf', :product_homepage_url => 'http://www.yealink.com/product_info.aspx?ProductsCateID=308')
    end
  end

  def down
    Manufacturer.where(:name => 'Yealink').destroy_all
    PhoneModel.where(:name => 'Yealink W52P').destroy_all
  end
end
