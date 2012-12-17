class CallHistoriesController < ApplicationController
  
  load_resource :sip_account

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
  
  before_filter { |controller|
    if ! params[:type].blank? then
      @type = params[:type].to_s
    end

    if ! params[:page].blank? then
      @pagination_page_number = params[:page].to_i
    end
  }

  def index
    hunt_group_member_ids = PhoneNumber.where(:phone_numberable_type => 'HuntGroupMember', :number => @sip_account.phone_numbers.map {|a| a.number}).map {|a| a.phone_numberable_id}
    hunt_group_ids = HuntGroupMember.where(:id => hunt_group_member_ids, :active => true).map {|a| a.hunt_group_id}
    calls = CallHistory.where('(call_historyable_type = "SipAccount" AND call_historyable_id = ?) OR (call_historyable_type = "HuntGroup" AND call_historyable_id IN (?))', @sip_account.id, hunt_group_ids).order('start_stamp DESC')
    
    @call_histories = calls.paginate(
      :page => @pagination_page_number,
      :per_page => DEFAULT_PAGINATION_ENTRIES_PER_PAGE
    )

    @calls_count = calls.count
    @calls_received_count = calls.where(:entry_type => 'received').count
    @calls_dialed_count = calls.where(:entry_type => 'dialed').count
    @calls_missed_count = calls.where(:entry_type => 'missed').count
    @calls_forwarded_count = calls.where(:entry_type => 'forwarded').count

    if ! @type.blank?
      @call_histories = @call_histories.where(:entry_type => @type)
    end
  end


  def destroy
    @call_history = CallHistory.where(:id => params[:id]).first
    if can?(:destroy, @call_history)
      @call_history.destroy
      m = method( :"#{@parent.class.name.underscore}_call_histories_url" )
      redirect_to m.(), :notice => t('call_histories.controller.successfuly_destroyed')
    end
  end

  def destroy_multiple
    if ! params[:selected_ids].blank? then
      result = @sip_account.call_histories.where(:id => params[:selected_ids]).destroy_all();
    end

    m = method( :"#{@parent.class.name.underscore}_call_histories_url" )
    if result
      redirect_to m.(), :notice => t('call_histories.controller.successfuly_destroyed')
    else
      redirect_to m.()
    end
  end

  def call
    @call_history = CallHistory.where(:id => params[:id]).first
    if can?(:call, @call_history) && @sip_account.registration
      phone_number = @call_history.display_number
      if ! phone_number.blank? 
        @sip_account.call(phone_number)
      end
    end
    redirect_to(:back)
  end

  private
  def set_and_authorize_parent
    @parent = @sip_account

    authorize! :read, @parent

    @show_path_method = method( :"#{@parent.class.name.underscore}_call_history_path" )
    @index_path_method = method( :"#{@parent.class.name.underscore}_call_histories_path" )
    @new_path_method = method( :"new_#{@parent.class.name.underscore}_call_history_path" )
    @edit_path_method = method( :"edit_#{@parent.class.name.underscore}_call_history_path" )
  end

  def spread_breadcrumbs
    if @parent.class == SipAccount
     if @sip_account.sip_accountable.class == User
       add_breadcrumb t("#{@sip_account.sip_accountable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore.pluralize}_path" ).(@sip_account.tenant)
       add_breadcrumb @sip_account.sip_accountable, method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore}_path" ).(@sip_account.tenant, @sip_account.sip_accountable)
     end
     add_breadcrumb t("sip_accounts.index.page_title"), method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_accounts_path" ).(@sip_account.sip_accountable)
     add_breadcrumb @sip_account, method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_account_path" ).(@sip_account.sip_accountable, @sip_account)
     add_breadcrumb t("call_histories.index.page_title"), sip_account_call_histories_path(@sip_account)
     if @call_history && !@call_history.new_record?
       add_breadcrumb @call_history, sip_account_call_history_path(@sip_account, @call_history)
     end
    end
  end

end
