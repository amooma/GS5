class SwitchboardEntriesController < ApplicationController
  load_and_authorize_resource :switchboard
  authorize_resource :switchboard_entry, :through => :switchboard, :except => [:sort]

  def index
    @switchboard_entries = @switchboard.switchboard_entries
    spread_breadcrumbs
  end

  def show
    @switchboard_entry = @switchboard.switchboard_entries.find(params[:id])
    spread_breadcrumbs
  end

  def new
    @switchboard_entry = @switchboard.switchboard_entries.build
    @sip_accounts = SipAccount.all - @switchboard.sip_accounts
    spread_breadcrumbs
  end

  def create
    @switchboard_entry = @switchboard.switchboard_entries.build(switchboard_entry_params)
    spread_breadcrumbs
    if @switchboard_entry.save
      redirect_to switchboard_switchboard_entries_path(@switchboard), :notice => t('switchboard_entries.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @switchboard_entry = @switchboard.switchboard_entries.find(params[:id])
    @sip_accounts = SipAccount.all - @switchboard.sip_accounts + [@switchboard_entry.sip_account]
    spread_breadcrumbs
  end

  def update
    @switchboard_entry = @switchboard.switchboard_entries.find(params[:id])
    if @switchboard_entry.update_attributes(switchboard_entry_params)
      redirect_to [@switchboard, @switchboard_entry], :notice  => t('switchboard_entries.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @switchboard_entry = @switchboard.switchboard_entries.find(params[:id])
    @switchboard_entry.destroy
    redirect_to switchboard_switchboard_entries_path(@switchboard), :notice => t('switchboard_entries.controller.successfuly_destroyed')
  end

  def sort
    params[:switchboard_entry].reverse.each do |id|
      @switchboard.switchboard_entries.find(id).move_to_top
    end
    render nothing: true
  end

  private
  def switchboard_entry_params
    params.require(:switchboard_entry).permit(:name, :sip_account_id)
  end

  def spread_breadcrumbs
    add_breadcrumb t("users.index.page_title"), tenant_users_path(@switchboard.user.current_tenant)
    add_breadcrumb @switchboard.user, tenant_user_path(@switchboard.user.current_tenant, @switchboard.user)
    add_breadcrumb t("switchboards.index.page_title"), user_switchboards_path(@switchboard.user)
    add_breadcrumb @switchboard, user_switchboard_path(@switchboard.user, @switchboard)
    add_breadcrumb t("switchboard_entries.index.page_title"), switchboard_switchboard_entries_path(@switchboard)
    if @switchboard_entry && !@switchboard_entry.new_record?
      add_breadcrumb @switchboard_entry, switchboard_switchboard_entries_path(@switchboard, @switchboard_entry)
    end
  end   
end
