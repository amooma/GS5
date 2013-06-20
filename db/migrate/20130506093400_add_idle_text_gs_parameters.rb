class AddIdleTextGsParameters < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'phones', :section => 'snom', :name => 'user_idle_text', :value => '{caller_name}', :class_type => 'String', :description => 'Name shown on the idle screen')
  end

  def down
  	GsParameter.where(:entity => 'phones', :section => 'snom', :name => 'user_idle_text').destroy_all
  end
end
