class AddSiteToGsNode < ActiveRecord::Migration
  def change
    add_column :gs_nodes, :site, :string

    add_column :gs_nodes, :element_name, :string

    rename_column :gs_nodes, :push_updates, :push_updates_to

    add_column :gs_nodes, :accepts_updates_from, :boolean

  end
end
