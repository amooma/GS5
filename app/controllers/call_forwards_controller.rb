class CallForwardsController < ApplicationController
  load_resource :phone_number
  load_resource :sip_account
  load_resource :automatic_call_distributor
  load_resource :hunt_group

  load_and_authorize_resource :call_forward, :through => [:phone_number, :sip_account, :automatic_call_distributor, :hunt_group]
  
  before_filter :set_and_authorize_parent
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
    @call_forward = @parent.call_forwards.build
    @call_forward.depth = GsParameter.get('DEFAULT_CALL_FORWARD_DEPTH')
    @call_forward.active = true
    @call_forwarding_destinations = call_forwarding_destination_types()
    @call_forward.destination = GsParameter.get('CALLFORWARD_DESTINATION_DEFAULT').to_s if defined?(GsParameter.get('CALLFORWARD_DESTINATION_DEFAULT'))
    @destination_phone_number = @call_forward.destination

    @available_call_forward_cases = []
    CallForwardCase.all.each do |available_call_forward_case|
      if GuiFunction.display?("call_forward_case_#{available_call_forward_case.value}_field_in_call_forward_form", current_user)
        @available_call_forward_cases << available_call_forward_case
      end
    end

    if @parent.call_forwards.where(
      :call_forward_case_id => CallForwardCase.find_by_value('noanswer').id,
      :active => true
    ).count == 0
      @call_forward.call_forward_case_id = CallForwardCase.find_by_value('noanswer').id
      @call_forward.timeout = 45
    end

    @available_greetings = available_greetings()
  end

  def create
    @call_forward = @parent.call_forwards.build( params[:call_forward] )
    
    if @call_forward.save
      m = method( :"#{@parent.class.name.underscore}_call_forwards_url" )
      redirect_to m.( @parent ), :notice => t('call_forwards.controller.successfuly_created')
    else
      @available_call_forward_cases = CallForwardCase.all
      render :new
    end
  end

  def edit
    @available_call_forward_cases = CallForwardCase.all
    @call_forwarding_destinations = call_forwarding_destination_types()
    @available_greetings = available_greetings()
    @destination_phone_number = @call_forward.destination if @call_forward.call_forwarding_destination == ':PhoneNumber'
  end

  def update
    @available_call_forward_cases = CallForwardCase.all
    if @call_forward.update_attributes(params[:call_forward])
      m = method( :"#{@parent.class.name.underscore}_call_forwards_url" )
      redirect_to m.( @parent ), :notice  => t('call_forwards.controller.successfuly_updated')
    else
      @call_forwarding_destinations = call_forwarding_destination_types()
      render :edit
    end
  end

  def destroy
    @call_forward.destroy
    m = method( :"#{@parent.class.name.underscore}_call_forwards_url" )
    redirect_to m.( @parent ), :notice => t('call_forwards.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @phone_number || @sip_account || @automatic_call_distributor || @hunt_group
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @parent 
      if @parent.class == PhoneNumber && @parent.phone_numberable_type == 'SipAccount'
        @sip_account = @parent.phone_numberable
      elsif @parent.class == PhoneNumber && @parent.phone_numberable_type == 'HuntGroup'
        add_breadcrumb t("hunt_groups.index.page_title"), tenant_hunt_groups_path(@parent.phone_numberable.tenant)
        add_breadcrumb @parent.phone_numberable, tenant_hunt_group_path(@parent.phone_numberable.tenant, @parent.phone_numberable)
        add_breadcrumb t("phone_numbers.index.page_title"), hunt_group_phone_numbers_path(@parent.phone_numberable)
        add_breadcrumb @parent, hunt_group_phone_number_path(@parent.phone_numberable, @parent)
      elsif @parent.class == HuntGroup
        add_breadcrumb t("hunt_groups.index.page_title"), tenant_hunt_groups_path(@parent.tenant)
        add_breadcrumb @parent, tenant_hunt_group_path(@parent.tenant, @parent)
      end

      if @sip_account
        if @sip_account.sip_accountable_type == 'User'
          @user = @sip_account.sip_accountable
          if @parent.class == PhoneNumber
            add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
            add_breadcrumb @user, tenant_users_path(@user.current_tenant, @user)
            add_breadcrumb t("sip_accounts.index.page_title"), user_sip_accounts_path(@user)
            add_breadcrumb @sip_account, user_sip_account_path(@user, @sip_account)
            add_breadcrumb t("phone_numbers.index.page_title"), sip_account_phone_numbers_path(@sip_account)
            add_breadcrumb @parent, sip_account_phone_number_path(@sip_account, @parent)
          elsif @parent.class == SipAccount
            add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
            add_breadcrumb @user, tenant_users_path(@user.current_tenant, @user)
            add_breadcrumb t("sip_accounts.index.page_title"), user_sip_accounts_path(@user)
          end
        end
        if @sip_account.sip_accountable_type == 'Tenant'
          @tenant = @sip_account.sip_accountable
          add_breadcrumb t("sip_accounts.index.page_title"), tenant_sip_accounts_path(@tenant)
          add_breadcrumb @sip_account, tenant_sip_account_path(@tenant, @sip_account)
        end
      end

      m = method( :"#{@parent.class.name.underscore}_call_forwards_url" )
      add_breadcrumb t("call_forwards.index.page_title"), m.(@parent)
      if @call_forward && !@call_forward.new_record?
        m = method( :"#{@parent.class.name.underscore}_call_forward_path" )
        add_breadcrumb @call_forward, m.(@parent, @call_forward)
      end
    end
  end

  def call_forwarding_destination_types
    destinations_hash = {}
    phone_number_destination = CallForwardingDestination.new()
    phone_number_destination.id = ':PhoneNumber'
    phone_number_destination.label = 'Phone Number'

    call_forwarding_destinations = [
      phone_number_destination,
    ]

    if @parent.class == SipAccount ||  @parent.class == User || @parent.class == Tenant
      @parent.voicemail_accounts.each do |voicemail_account|
        call_forwards_destination = CallForwardingDestination.new()
        call_forwards_destination.id = "#{voicemail_account.id}:VoicemailAccount"
        call_forwards_destination.label = "VoicemailAccount: #{voicemail_account.to_s}"
        if !destinations_hash[call_forwards_destination.id]
          destinations_hash[call_forwards_destination.id] = true
          call_forwarding_destinations << call_forwards_destination
        end
      end
    end

    if @parent.class == SipAccount
      sip_account = @parent
      group_ids = Group.target_group_ids_by_permission(:forward_to, sip_account.groups)

      if sip_account.sip_accountable.class == User || sip_account.sip_accountable.class == Tenant
        group_ids = group_ids + Group.target_group_ids_by_permission(:forward_to, sip_account.sip_accountable.groups)
        sip_account.sip_accountable.voicemail_accounts.each do |voicemail_account|
          call_forwards_destination = CallForwardingDestination.new()
          call_forwards_destination.id = "#{voicemail_account.id}:VoicemailAccount"
          call_forwards_destination.label = "VoicemailAccount: #{voicemail_account.to_s}" 
          if !destinations_hash[call_forwards_destination.id]
            destinations_hash[call_forwards_destination.id] = true
            call_forwarding_destinations << call_forwards_destination
          end
        end
      end

      GroupMembership.where(:group_id => group_ids, :item_type => 'VoicemailAccount').each do |group_member|
        call_forwards_destination = CallForwardingDestination.new()
        call_forwards_destination.id = "#{group_member.item.id}:VoicemailAccount"
        call_forwards_destination.label = "VoicemailAccount: #{group_member.item.to_s}" 
        if !destinations_hash[call_forwards_destination.id]
          destinations_hash[call_forwards_destination.id] = true
          call_forwarding_destinations << call_forwards_destination
        end
      end
    end

    if @parent.class == PhoneNumber
      if @parent.phone_numberable.class == SipAccount
        sip_account = @parent.phone_numberable
        if sip_account.sip_accountable.class == User || sip_account.sip_accountable.class == Tenant
          sip_account.sip_accountable.voicemail_accounts.each do |voicemail_account|
            call_forwards_destination = CallForwardingDestination.new()
            call_forwards_destination.id = "#{voicemail_account.id}:VoicemailAccount"
            call_forwards_destination.label = "VoicemailAccount: #{voicemail_account.to_s}" 
            if !destinations_hash[call_forwards_destination.id]
              destinations_hash[call_forwards_destination.id] = true
              call_forwarding_destinations << call_forwards_destination
            end
          end
        end
      end
    end

    if GuiFunction.display?('huntgroup_in_destination_field_in_call_forward_form', current_user)
      HuntGroup.all.each do |hunt_group|
        call_forwards_destination = CallForwardingDestination.new()
        call_forwards_destination.id = "#{hunt_group.id}:HuntGroup"
        call_forwards_destination.label = "HuntGroup: #{hunt_group.to_s}"
        if !destinations_hash[call_forwards_destination.id]
          destinations_hash[call_forwards_destination.id] = true
          call_forwarding_destinations << call_forwards_destination
        end
      end
    end

    return call_forwarding_destinations
  end

  def available_greetings
    if @parent.class == PhoneNumber
      owner = @parent.phone_numberable
    else
      owner = @parent
    end

    if owner.class == SipAccount
      owner = owner.sip_accountable
    elsif owner.class == FaxAccount
      owner = owner.fax_accountable
    end

    return GenericFile.where(:category => 'greeting', :owner_type => owner.class.to_s, :owner_id => owner.id).map {|x| [x.to_s, x.name] }
  end

end
