class AddClipToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :clip, :boolean
  end
end
