class GemeinschaftSetupsController < ApplicationController
  # We use the heater rake task to generate this file.
  # So it loads super fast even on slow machines.
  #
  caches_page :new, :gzip => :best_compression

  skip_before_filter :start_setup_if_new_installation

  load_and_authorize_resource :gemeinschaft_setup

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

    @gemeinschaft_setup.default_company_name = generate_a_new_name(Tenant.new)
    @gemeinschaft_setup.default_system_email = 'admin@localhost'
    @gemeinschaft_setup.trunk_access_code = '0'
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
                                            @gemeinschaft_setup.trunk_access_code, 
                                            @gemeinschaft_setup.default_area_code
                                            )

      # Set a couple of URLs in the GsParameter table
      GsParameter.where(:name => 'phone_book_entry_image_url').first.update_attributes(:value => "http://#{@gemeinschaft_setup.sip_domain.host}/uploads/phone_book_entry/image")
      GsParameter.where(:name => 'ringtone_url').first.update_attributes(:value => "http://#{@gemeinschaft_setup.sip_domain.host}")
      GsParameter.where(:name => 'user_image_url').first.update_attributes(:value => "http://#{@gemeinschaft_setup.sip_domain.host}/uploads/user/image")

      # Set ringback_tone
      if @gemeinschaft_setup.country.country_code.to_s == '49'
        GsParameter.where(:entity => 'dialplan', :section => 'variables', :name => 'ringback').first.update_attributes(:value => '%(1000,4000,425.0)')
      end

      # Restart FreeSWITCH
      if Rails.env.production?
        require 'freeswitch_event'
        FreeswitchAPI.execute('fsctl', 'shutdown restart')
      end

      # Create the tenant
      tenant = Tenant.create({:name => @gemeinschaft_setup.default_company_name, 
                              :sip_domain_id => SipDomain.last.id,
                              :country_id => @gemeinschaft_setup.country.id,
                              :language_id => @gemeinschaft_setup.language_id,
                              :from_field_voicemail_email => @gemeinschaft_setup.default_system_email,
                              :from_field_pin_change_email => @gemeinschaft_setup.default_system_email,
                             })

      # Become a member of this tenant.
      #
      tenant.tenant_memberships.create(:user_id => user.id)
      
      # Groups
      #
      admin_group = tenant.user_groups.create(:name => t('gemeinschaft_setups.initial_setup.admin_group_name'))
      admin_group.users << user
      
      user_group = tenant.user_groups.create(:name => t('gemeinschaft_setups.initial_setup.user_group_name'))
      user_group.users << user
      
      user.update_attributes!(:current_tenant_id => tenant.id)

      # Auto-Login:
      session[:user_id] = user.id
      
      # Perimeter settings
      if !@gemeinschaft_setup.detect_attacks
        detect_attacks = GsParameter.where(:entity => 'events', :section => 'modules', :name => 'perimeter_defense').first
        if detect_attacks
          detect_attacks.update_attributes(:value => '0', :class_type => 'Integer')
        end
      end

      if !@gemeinschaft_setup.report_attacks
        GsParameter.create(:entity => 'perimeter', :section => 'general', :name => 'report_url', :value => '', :class_type => 'String', :description => '')
        report_url = GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'report_url').first
        if report_url
          report_url.update_attributes(:value => '', :class_type => 'String')
        end
      end

      # Redirect to the user
      redirect_to page_help_path, :notice => t('gemeinschaft_setups.initial_setup.successful_setup')
    else
      render :new
    end
  end
  
end
