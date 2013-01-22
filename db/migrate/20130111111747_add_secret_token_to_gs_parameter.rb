class AddSecretTokenToGsParameter < ActiveRecord::Migration
  def up
  	require 'securerandom'
    GsParameter.create(:name => 'SECRET_TOKEN', :section => 'Cookies', :value => SecureRandom.hex(64), :class_type => 'String')
  end

  def down
		GsParameter.where(:name => 'SECRET_TOKEN').destroy_all
  end
end
