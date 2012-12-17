# ruby encoding: utf-8

class SnomPhones < ActiveRecord::Migration
  def up
  ################################################################
  # Manufacturers
  ################################################################
  add_column :phone_models, :uuid, :string rescue puts "column already added"
  snom = Manufacturer.find_or_create_by_ieee_name('SNOM Technology AG', 
            {
              :name => "SNOM Technology AG",
              :homepage_url => 'http://www.snom.com'
            }
          )


  ################################################################
  # OUIs
  ################################################################

  snom.ouis.find_or_create_by_value('000413')


  ################################################################
  # Phone models
  ################################################################

  snom300 = snom.phone_models.create(:name => 'Snom 300', 
                                    :product_homepage_url => 'http://www.snom.com/en/products/ip-phones/snom-300/',
                                    :product_manual_homepage_url => 'http://wiki.snom.com/Snom300/Documentation')

  snom320 = snom.phone_models.create(:name => 'Snom 320', 
                                :product_homepage_url => 'http://www.snom.com/en/products/ip-phones/snom-320/',
                                :product_manual_homepage_url => 'http://wiki.snom.com/Snom320/Documentation')

  snom360 = snom.phone_models.create(:name => 'Snom 360', 
                                :product_homepage_url => 'http://www.snom.com/en/products/ip-phones/snom-360/',
                                :product_manual_homepage_url => 'http://wiki.snom.com/Snom360/Documentation')

  snom370 = snom.phone_models.create(:name => 'Snom 370', 
                                :product_homepage_url => 'http://www.snom.com/en/products/ip-phones/snom-370/',
                                :product_manual_homepage_url => 'http://wiki.snom.com/Snom370/Documentation')

  snom820 = snom.phone_models.create(:name => 'Snom 820', 
                                :product_homepage_url => 'http://www.snom.com/en/products/ip-phones/snom-820/',
                                :product_manual_homepage_url => 'http://wiki.snom.com/Snom820/Documentation')
                                
  snom821 = snom.phone_models.create(:name => 'Snom 821', 
                                :product_homepage_url => 'http://www.snom.com/en/products/ip-phones/snom-821/',
                                :product_manual_homepage_url => 'http://wiki.snom.com/Snom821/Documentation')
                          
  snom870 = snom.phone_models.create(:name => 'Snom 870', 
                                :product_homepage_url => 'http://www.snom.com/en/products/ip-phones/snom-870/',
                                :product_manual_homepage_url => 'http://wiki.snom.com/Snom870/Documentation')                                                     

  end

  def down
    Manufacturer.destroy_all
    Oui.destroy_all
    PhoneModel.destroy_all
  end
end
