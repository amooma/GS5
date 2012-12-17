# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :user_group_membership do |f|
  f.association :user_group
  f.association :user
  
  # Make sure that the User is a member of the Tenant.
  f.after_build do |instance|
    Factory.create(:tenant_membership,
      :tenant_id => instance.user_group.tenant.id,
      :user_id   => instance.user.id
    )
  end
end