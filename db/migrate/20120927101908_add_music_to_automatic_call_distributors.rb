class AddMusicToAutomaticCallDistributors < ActiveRecord::Migration
  def change
    add_column :automatic_call_distributors, :music, :string

  end
end
