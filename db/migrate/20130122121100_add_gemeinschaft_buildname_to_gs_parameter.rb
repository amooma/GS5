class AddGemeinschaftBuildnameToGsParameter < ActiveRecord::Migration
  def up
    GsParameter.create(:name => 'GEMEINSCHAFT_BUILDNAME', :section => 'Generic', :value => '', :class_type => 'String')
  end

  def down
    GsParameter.where(:name => 'GEMEINSCHAFT_BUILDNAME').destroy_all
  end
end
