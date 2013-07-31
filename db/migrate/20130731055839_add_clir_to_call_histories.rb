class AddClirToCallHistories < ActiveRecord::Migration
  def change
    add_column :call_histories, :clir, :boolean
  end
end
