class AddClipNumberToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :clip, :string
    remove_column :sip_accounts, :clip_phone_number_id
  end
end
