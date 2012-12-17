class PopulateSoftkeyFunctions < ActiveRecord::Migration
  def up
  	SoftkeyFunction.create(:name => 'call_forwarding')
  end

  def down
  	SoftkeyFunction.where(:name => 'call_forwarding').destroy_all
  end
end
