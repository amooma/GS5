# ruby encoding: utf-8

class CallForwardCases < ActiveRecord::Migration
  def up
		################################################################
		# Call forward cases
		################################################################

		[
		  'always',
		  'busy',
		  'noanswer',
		  'offline',
		  'assistant',
		].each { |case_name|
		  CallForwardCase.create( :value => case_name )
		}
  end

  def down
  	CallForwardCase.destroy_all
  end
end
