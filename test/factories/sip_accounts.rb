# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :sip_account do |f|
  f.association :sip_accountable, :factory => :user
  f.sequence(:auth_name) {|n| "auth_name#{n}" }
  f.sequence(:caller_name) {|n| "Foo Account #{n}" }
  f.sequence(:password) {|n| "12345678" }
  
  f.after_build do |sip_account|
    if sip_account.tenant_id.blank?
      tenant = sip_account.create_tenant(FactoryGirl.build(:tenant).attributes)
      sip_domain = tenant.create_sip_domain(FactoryGirl.build(:sip_domain).attributes)
      sip_account.tenant.tenant_memberships.create(:user_id => sip_account.sip_accountable.id)
      sip_account.tenant_id = tenant.id
    end
  end
end
