class AddNumberOfShownItemsToGsParameter < ActiveRecord::Migration
  def up
    GsParameter.create(:name => 'NUMBER_OF_SHOWN_ITEMS', :section => 'Views', :value => '10', :class_type => 'Integer')
  end

  def down
    GsParameter.where(:name => 'NUMBER_OF_SHOWN_ITEMS').destroy_all
  end
end
