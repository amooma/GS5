class ShowAdminAutoOnlineHelp < ActiveRecord::Migration
  def up
    GsParameter.create(:name => 'AUTO_ADMIN_ONLINE_HELP', :section => 'Documentation', :value => 'true', :class_type => 'Boolean', :description => 'Gemeinschaft will include tips and help whenever it seems fit.')
  end

  def down
  	GsParameter.where(:name => 'AUTO_ADMIN_ONLINE_HELP').destroy_all
  end
end
