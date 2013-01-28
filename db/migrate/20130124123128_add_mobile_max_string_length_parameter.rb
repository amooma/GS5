class AddMobileMaxStringLengthParameter < ActiveRecord::Migration
  def up
    GsParameter.create(:name => 'MOBILE_MAX_STRING_LENGTH', :section => 'HTML', :value => '8', :class_type => 'Integer', :description => 'Max length of a string on a mobile devise.')
    GsParameter.create(:name => 'DESKTOP_MAX_STRING_LENGTH', :section => 'HTML', :value => '30', :class_type => 'Integer', :description => 'Max length of a string on a desktop devise.')
  end

  def down
  	GsParameter.where(:name => 'MOBILE_MAX_STRING_LENGTH').destroy_all
  	GsParameter.where(:name => 'DESKTOP_MAX_STRING_LENGTH').destroy_all
  end
end
