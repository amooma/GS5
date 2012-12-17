class AddAnnounceCallAgentsToAutomaticCallDistributors < ActiveRecord::Migration
  def change
    add_column :automatic_call_distributors, :announce_call_agents, :boolean

  end
end
