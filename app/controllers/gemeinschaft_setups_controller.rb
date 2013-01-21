class GemeinschaftSetupsController < ApplicationController
  # We use the heater rake task to generate this file.
  # So it loads super fast even on slow machines.
  #
  caches_page :new, :gzip => :best_compression

  load_and_authorize_resource :gemeinschaft_setup

  skip_before_filter :go_to_setup_if_new_installation

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
                                    :name => GsParameter.get('SUPER_TENANT_NAME'),
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

      # Set CallRoute defaults
      CallRoute.factory_defaults_prerouting(@gemeinschaft_setup.country.country_code, 
                                            @gemeinschaft_setup.country.trunk_prefix, 
                                            @gemeinschaft_setup.country.international_call_prefix, 
                                            '', 
                                            @gemeinschaft_setup.default_area_code
                                            )

      # Set a couple of URLs in the GsParameter table
      GsParameter.where(:name => 'phone_book_entry_image_url').first.update_attributes(:value => "http://#{@gemeinschaft_setup.sip_domain.host}/uploads/phone_book_entry/image")
      GsParameter.where(:name => 'ringtone_url').first.update_attributes(:value => "http://#{@gemeinschaft_setup.sip_domain.host}")
      GsParameter.where(:name => 'user_image_url').first.update_attributes(:value => "http://#{@gemeinschaft_setup.sip_domain.host}/uploads/user/image")

      # Restart FreeSWITCH
      if Rails.env.production?
        require 'freeswitch_event'
        FreeswitchAPI.execute('fsctl', 'shutdown restart')
      end

      # Auto-Login:
      session[:user_id] = user.id
      
      # Redirect to the user
      redirect_to new_tenant_url, :notice => t('gemeinschaft_setups.initial_setup.successful_setup')
    else
      render :new
    end
  end
  
end
