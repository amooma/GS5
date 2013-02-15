class AddSimCardGsParameter < ActiveRecord::Migration
  def up
    GsParameter.create(:name => 'SIM_CARDS', :section => 'System defaults', :value => 'false', :class_type => 'Boolean', :description => 'Should it be possible to use SIM cards as SIP account users.')
  end

  def down
  	GsParameter.where(:name => 'SIM_CARDS').destroy_all
  end
end
