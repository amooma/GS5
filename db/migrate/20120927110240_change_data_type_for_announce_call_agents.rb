class ChangeDataTypeForAnnounceCallAgents < ActiveRecord::Migration
  def up
    change_table :automatic_call_distributors do |t|
      t.change :announce_call_agents, :string
    end
  end

  def down
    change_table :automatic_call_distributors do |t|
      t.change :announce_call_agents, :boolean
    end
  end
end
