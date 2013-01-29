class CallForwardsController < ApplicationController
  load_and_authorize_resource :phone_number
  load_and_authorize_resource :call_forward, :through => [:phone_number]
  
  before_filter :spread_breadcrumbs

  class CallForwardingDestination
    attr_accessor :id, :label

    def to_s
      return label
    end
  end


  def index
  end

  def show
  end

  def new
    @call_forward = @phone_number.call_forwards.build
    @call_forward.depth = GsParameter.get('DEFAULT_CALL_FORWARD_DEPTH')
    @call_forward.active = true
    @call_forwarding_destinations = call_forwarding_destination_types()
    @call_forward.destination = GsParameter.get('CALLFORWARD_DESTINATION_DEFAULT').to_s if defined?(GsParameter.get('CALLFORWARD_DESTINATION_DEFAULT'))

    @available_call_forward_cases = []
    CallForwardCase.all.each do |available_call_forward_case|
      if GuiFunction.display?("call_forward_case_#{available_call_forward_case.value}_field_in_call_forward_form", current_user)
        @available_call_forward_cases << available_call_forward_case
      end
    end

    if @phone_number.call_forwards.where(
      :call_forward_case_id => CallForwardCase.find_by_value('noanswer').id,
      :active => true
    ).count == 0
      @call_forward.call_forward_case_id = CallForwardCase.find_by_value('noanswer').id
      @call_forward.timeout = 45
    end
  end

  def create
    @call_forward = @phone_number.call_forwards.build( params[:call_forward] )
    
    if @call_forward.save
      redirect_to phone_number_call_forward_path( @phone_number, @call_forward ), :notice => t('call_forwards.controller.successfuly_created')
    else
      @available_call_forward_cases = CallForwardCase.all
      render :new
    end
  end

  def edit
    @available_call_forward_cases = CallForwardCase.all
    @call_forwarding_destinations = call_forwarding_destination_types()
  end

  def update
    @available_call_forward_cases = CallForwardCase.all
    if @call_forward.update_attributes(params[:call_forward])
      redirect_to phone_number_call_forward_path( @phone_number, @call_forward ), :notice  => t('call_forwards.controller.successfuly_updated')
    else
      @call_forwarding_destinations = call_forwarding_destination_types()
      render :edit
    end
  end

  def destroy
    @call_forward.destroy
    redirect_to phone_number_call_forwards_path( @phone_number ), :notice => t('call_forwards.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    if @phone_number && @phone_number.phone_numberable_type == 'SipAccount'
      @sip_account = @phone_number.phone_numberable
      if @sip_account.sip_accountable_type == 'User'
        @user = @phone_number.phone_numberable.sip_accountable
        add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
        add_breadcrumb @user, tenant_users_path(@user.current_tenant, @user)
        add_breadcrumb t("sip_accounts.index.page_title"), user_sip_accounts_path(@user)
        add_breadcrumb @sip_account, user_sip_account_path(@user, @sip_account)
      end
      if @sip_account.sip_accountable_type == 'Tenant'
        @tenant = @sip_account.sip_accountable
        add_breadcrumb t("sip_accounts.index.page_title"), tenant_sip_accounts_path(@tenant)
        add_breadcrumb @sip_account, tenant_sip_account_path(@tenant, @sip_account)
      end
      add_breadcrumb t("phone_numbers.index.page_title"), sip_account_phone_numbers_path(@sip_account)
      add_breadcrumb @phone_number, sip_account_phone_number_path(@sip_account, @phone_number)
      add_breadcrumb t("call_forwards.index.page_title"), phone_number_call_forwards_path(@phone_number)
      if @call_forward && !@call_forward.new_record?
        add_breadcrumb @call_forward, phone_number_call_forward_path(@phone_number, @call_forward)
      end
    end
  end

  def call_forwarding_destination_types

    phone_number_destination = CallForwardingDestination.new()
    phone_number_destination.id = ':PhoneNumber'
    phone_number_destination.label = 'Phone Number'
    voice_mail_destination = CallForwardingDestination.new()
    voice_mail_destination.id = ':Voicemail'
    voice_mail_destination.label = 'Voice Mail'

    call_forwarding_destinations = [
      phone_number_destination,
      voice_mail_destination,
    ]

    if GuiFunction.display?('huntgroup_in_destination_field_in_call_forward_form', current_user)
      HuntGroup.all.each do |hunt_group|
        hunt_group_destination = CallForwardingDestination.new()
        hunt_group_destination.id = "#{hunt_group.id}:HuntGroup"
        hunt_group_destination.label = "HuntGroup: #{hunt_group.to_s}"
        call_forwarding_destinations.push(hunt_group_destination)
      end
    end

    return call_forwarding_destinations
  end

end
