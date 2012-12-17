class CallforwardRulesActPerSipAccountToSipAccount < ActiveRecord::Migration
  def change
    add_column :sip_accounts, :callforward_rules_act_per_sip_account, :boolean
  end
end
