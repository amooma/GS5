class AddEntityToGsParameter < ActiveRecord::Migration
  def change
    add_column :gs_parameters, :entity, :string, :after => :id

  end
end
