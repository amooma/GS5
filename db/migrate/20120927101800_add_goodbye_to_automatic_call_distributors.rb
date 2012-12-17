class AddGoodbyeToAutomaticCallDistributors < ActiveRecord::Migration
  def change
    add_column :automatic_call_distributors, :goodbye, :string

  end
end
