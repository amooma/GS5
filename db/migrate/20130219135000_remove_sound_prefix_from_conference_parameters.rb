class RemoveSoundPrefixFromConferenceParameters < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'conferences', :section => 'parameters', :name => 'sound-prefix').destroy_all
  end

  def down
  end
end
