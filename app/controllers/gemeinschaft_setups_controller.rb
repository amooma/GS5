class GemeinschaftSetupsController < ApplicationController
  load_and_authorize_resource :gemeinschaft_setup

  skip_before_filter :go_to_setup_if_new_installation
  # before_filter :redirect_if_not_a_fresh_installation

  def new
    @user = @gemeinschaft_setup.build_user(
                                            :user_name => t('gemeinschaft_setups.initial_setup.admin_name'), 
                                            :male => true,
                                            :email => 'admin@localhost',
                                          )
    @sip_domain = @gemeinschaft_setup.build_sip_domain(
      :host  => guess_local_host(),
      :realm => guess_local_host(),
    )
    @gemeinschaft_setup.country  = Country.find_by_name('Germany')
    @gemeinschaft_setup.language = Language.find_by_name('Deutsch')
  end

  def create
    if @gemeinschaft_setup.save
      super_tenant = Tenant.create(
                                    :name => SUPER_TENANT_NAME,
                                    :country_id  => @gemeinschaft_setup.country.id, 
                                    :language_id => @gemeinschaft_setup.language_id,
                                    :description => t('gemeinschaft_setups.initial_setup.super_tenant_description'),
                                  )

      # GsNode
      GsNode.create(:name => 'Homebase', :ip_address => @gemeinschaft_setup.sip_domain.host, 
                    :push_updates_to => false, :accepts_updates_from => false, 
                    :site => 'Homebase', :element_name => 'Homebase')
      
      # Admin
      user = @gemeinschaft_setup.user
      super_tenant.tenant_memberships.create(:user_id => user.id)
      user.update_attributes(:current_tenant_id => super_tenant.id)

      # Create the Super-Tenant's group:
      super_tenant_super_admin_group = super_tenant.user_groups.create(:name => t('gemeinschaft_setups.initial_setup.super_admin_group_name'))
      super_tenant_super_admin_group.user_group_memberships.create(:user_id => user.id)

      # Auto-Login:
      session[:user_id] = user.id
      
      # Redirect to the user
      redirect_to new_tenant_url, :notice => t('gemeinschaft_setups.initial_setup.successful_setup')
    else
      render :new
    end
  end
  
  private
  
  def redirect_if_not_a_fresh_installation
    if GemeinschaftSetup.all.count > 0
      if current_user
        redirect_to root_url    , :alert => t('gemeinschaft_setups.initial_setup.access_denied_only_available_on_a_new_system')
      else
        redirect_to log_in_path , :alert => t('gemeinschaft_setups.initial_setup.access_denied_only_available_on_a_new_system')
      end
    end
  end
  
end
