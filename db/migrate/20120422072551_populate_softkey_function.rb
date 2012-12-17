class PopulateSoftkeyFunction < ActiveRecord::Migration
  def up
   	['speed_dial', 'blf', 'dtmf', 'log_out', 'log_in', 'conference'].each do |function_name|
		SoftkeyFunction.create(:name => function_name)
	end

    	SoftkeyFunction.where(:position => nil).order(:id).each do |softkey_function|
  		softkey_function.update_attributes(:position => softkey_function.id) if softkey_function.position.nil?
  	end
  	deactivated_softkey_function = SoftkeyFunction.create(:name => 'deactivated')
  	deactivated_softkey_function.move_to_top
  end

  def down
  	SoftkeyFunction.where(:name =>  ['speed_dial', 'blf', 'dtmf', 'log_out', 'log_in', 'conference', 'deactivated'] ).destroy_all
  end

end
