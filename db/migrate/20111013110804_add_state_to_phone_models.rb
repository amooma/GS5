class AddStateToPhoneModels < ActiveRecord::Migration
  def change
    add_column :phone_models, :state, :string
  end
end
