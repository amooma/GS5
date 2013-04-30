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

  def sortable(column, title)
    if !defined?(sort_descending)
      return title
    end

    if column.to_s == sort_column.to_s
      link_class = "sort_descending #{sort_descending}"
      desc = !!(!sort_descending && column)
      icon = sort_descending ? ' <i class = "icon-chevron-up"></i> ' : ' <i class = "icon-chevron-down"></i> '
    else
      link_class = nil
      desc = nil
      icon = ''
    end

    link_to raw('') + title + raw(icon), {:sort => column, :desc => desc, :type => @type}, {:class => link_class}
  end

end
