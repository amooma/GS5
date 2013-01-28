class AddVoicemailStorageParameter < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'voicemail', :section => 'parameters', :name => 'storage-dir',  :value => '/var/lib/freeswitch/voicemail', :class_type => 'String', :description => 'Directory where voicemail messages are stored.')
  end

  def down
  	GsParameter.where(:entity => 'voicemail', :section => 'parameters', :name => 'storage-dir').destroy_all
  end
end
