class AddGreetingToAutomaticCallDistributors < ActiveRecord::Migration
  def change
    add_column :automatic_call_distributors, :greeting, :string

  end
end
