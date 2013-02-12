class AddSsoKey < ActiveRecord::Migration
  def up
    GsParameter.create(:name => 'SingleSignOnEnvUserNameKey', :section => 'Generic', :value => '', :class_type => 'Nil', :description => 'When set to a string this env variable will be used to authenticate the user. e.g. REMOTE_USER')
  end

  def down
  	GsParameter.create(:name => 'SingleSignOnEnvUserNameKey').destroy_all
  end
end
