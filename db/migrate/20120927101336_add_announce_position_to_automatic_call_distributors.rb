class AddAnnouncePositionToAutomaticCallDistributors < ActiveRecord::Migration
  def change
    add_column :automatic_call_distributors, :announce_position, :integer

  end
end
