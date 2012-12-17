class AddAnnouncementOfANewMemberToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :announce_new_member_by_name, :boolean
    add_column :conferences, :announce_left_member_by_name, :boolean
  end
end
