class SnomMeetingpoint < ActiveRecord::Migration
  def up
  	if Manufacturer.where(:ieee_name => 'SNOM Technology AG').any?
	  	snom = Manufacturer.where(:ieee_name => 'SNOM Technology AG').first
  	  snom.phone_models.create(:name => 'snom MeetingPoint', 
                               :product_homepage_url => 'http://www.snom.com/en/products/sip-conference-phone/snom-meetingpoint/',
                               :product_manual_homepage_url => 'http://wiki.snom.com/Snom_MeetingPoint/Documentation')
	  end
  end

  def down
  	PhoneModels.where(:name => 'snom MeetingPoint').destroy_all
  end
end
