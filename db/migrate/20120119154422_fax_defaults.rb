# ruby encoding: utf-8

class FaxDefaults < ActiveRecord::Migration
  def up
	################################################################
	# Fax resolutions
	################################################################
	FaxResolution.create(:name => 'Standard', :resolution_value => '204x98')
	FaxResolution.create(:name => 'Fine', :resolution_value => '204x196')
  end

  def down
    FaxResolution.destroy_all
  end
end
