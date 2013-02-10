class Intruder < ActiveRecord::Base
  attr_accessible :list_type, :key, :points, :bans, :ban_last, :ban_end, :contact_ip, :contact_port, :contact_count, :contact_last, :contacts_per_second, :contacts_per_second_max, :user_agent, :to_user, :comment
end
