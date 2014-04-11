class AddPingtelPhone < ActiveRecord::Migration
  def up
    Manufacturer.create(:name => 'Pingtel', :ieee_name => 'PINGTEL CORP.', :homepage_url => '')
    pingtel = Manufacturer.where(:name => 'Pingtel').first
    if pingtel
      pingtel.phone_models.create(:name => 'Pingtel Xpressa PX-1', :product_manual_homepage_url => '', :product_homepage_url => '')
    end
  end

  def down
    PhoneModel.where(:name => 'Pingtel Xpressa PX-1').destroy_all
    Manufacturer.where(:name => 'Pingtel').destroy_all
  end
end
