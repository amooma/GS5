class AddFallbackSipAccountToPhone < ActiveRecord::Migration
  def change
    add_column :phones, :fallback_sip_account_id, :integer

  end
end
