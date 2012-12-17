class AddUuidToPhoneModels < ActiveRecord::Migration
  def change
    add_column :phone_models, :uuid, :string rescue puts "column already added"

  end
end
