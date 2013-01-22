class TenantsController < ApplicationController
  authorize_resource :tenant
  
  def index
    @tenants = Tenant.scoped
  end

  def show
    @tenant = Tenant.find(params[:id])
    @gateways = Gateway.order(:updated_at)
  end

  def new
    @tenant = Tenant.new
    @tenant.name = generate_a_new_name(@tenant)
    @tenant.sip_domain = SipDomain.last
    @tenant.country  = GemeinschaftSetup.first.country
    @tenant.language = GemeinschaftSetup.first.language
    @tenant.internal_extension_ranges = '10-99'
    @tenant.from_field_voicemail_email = 'admin@localhost'
    @tenant.from_field_pin_change_email = 'admin@localhost'
  end

  def create
    @tenant = Tenant.new(tenant_params)

    if @tenant.save
      # Become a member of this tenant.
      #
      @tenant.tenant_memberships.create(:user_id => @current_user.id)
      
      # Groups
      #
      admin_group = @tenant.user_groups.create(:name => t('gemeinschaft_setups.initial_setup.admin_group_name'))
      admin_group.users << @current_user
      
      user_group = @tenant.user_groups.create(:name => t('gemeinschaft_setups.initial_setup.user_group_name'))
      user_group.users << @current_user
      
      @current_user.update_attributes!(:current_tenant_id => @tenant.id)
      
      # Generate the internal_extensions
      #
      if !@tenant.internal_extension_ranges.blank?
        if @tenant.array_of_internal_extension_numbers.count < 105
          # This can be done more or less quick.
          @tenant.generate_internal_extensions
        else
          # Better be on the save side and start a delayed job for this.
          @tenant.delay.generate_internal_extensions
        end
      end
      
      # Generate the external numbers (DIDs)
      #
      if !@tenant.did_list.blank?
        if @tenant.array_of_dids.count < 105
          # This can be done more or less quick.
          @tenant.generate_dids
        else
          # Better be on the save side and start a delayed job for this.
          @tenant.delay.generate_dids
        end
      end
       
      if Delayed::Job.count > 0
        if SipAccount.any? || Phone.any?
          redirect_to @tenant, :notice => t('tenants.controller.successfuly_created_plus_delayed_jobs', 
                                          :resource => @tenant, 
                                          :amount_of_numbers => @tenant.array_of_internal_extension_numbers.count + @tenant.array_of_dids.count
                                          )
        else
          redirect_to page_beginners_intro_path, :notice => t('tenants.controller.successfuly_created_plus_delayed_jobs', 
                                          :resource => @tenant, 
                                          :amount_of_numbers => @tenant.array_of_internal_extension_numbers.count + @tenant.array_of_dids.count
                                          )
        end
      else
        if SipAccount.any? || Phone.any?
          redirect_to @tenant, :notice => t('tenants.controller.successfuly_created', 
                                            :resource => @tenant
                                            )
        else
          redirect_to page_beginners_intro_path, :notice => t('tenants.controller.successfuly_created', 
                                            :resource => @tenant
                                            )
        end
      end
    else
      render :new
    end
  end

  def edit
    @tenant = Tenant.find(params[:id])
  end

  def update
    @tenant = Tenant.find(params[:id])
    if @tenant.update_attributes(tenant_params)
      redirect_to @tenant, :notice  => t('tenants.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @tenant = Tenant.find(params[:id])
    @tenant.destroy
    redirect_to tenants_url, :notice => t('tenants.controller.successfuly_destroyed')
  end

  private
  def tenant_params
    params.require(:tenant).permit(:name, :description, :sip_domain_id, :country_id, :language_id, :from_field_pin_change_email, :from_field_voicemail_email
)
  end
  
end
