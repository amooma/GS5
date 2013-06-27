class SwitchboardEntrySerializer < ActiveModel::Serializer
  attributes :id, :name, :path_to_user, :avatar_src, :callstate, :switchable

  has_one :sip_account, embed: :ids
  has_one :switchboard, embed: :ids

  def path_to_user
    if object.sip_account && object.sip_account.sip_accountable_type == 'User'
      "/tenants/#{object.sip_account.sip_accountable.current_tenant.id}/users/#{object.sip_account.sip_accountable.id}"
    else
      nil
    end
  end
end
