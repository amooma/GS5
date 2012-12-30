module ApplicationHelper

  # nicely_joined_with_commata(['1', '2', '3', '4'])
  # = '1, 2, 3 und 4'
  #
	def nicely_joined_with_commata(array_of_things)
		if array_of_things.count == 1
			array_of_things.first.to_s
		else
			if array_of_things.count > 1
        output = array_of_things[0, array_of_things.count - 1].map{|item| item.to_s}.join(', ')
        if I18n.locale == :de
          output += ' und '
        else
        	output += ' and '
        end
        output += array_of_things.last.to_s
      end
    end
	end

end
