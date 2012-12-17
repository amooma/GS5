class GuiFunctionMembership < ActiveRecord::Base
	belongs_to :gui_function
	belongs_to :user_group

	validates_associated :gui_function
	validates_associated :user_group
end
