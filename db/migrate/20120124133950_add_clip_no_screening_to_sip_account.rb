class AddClipNoScreeningToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :clip_no_screening, :string
    remove_column :sip_accounts, :clip
  end
end
