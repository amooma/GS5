class SwitchboardsController < ApplicationController
  load_and_authorize_resource :user
  authorize_resource :switchboard, :through => :user

  def index
    @switchboards = @user.switchboards
    spread_breadcrumbs
  end

  def show
    @switchboard = @user.switchboards.find(params[:id])
    @switchboard_entries = @switchboard.switchboard_entries
    spread_breadcrumbs
  end

  def new
    @switchboard = @user.switchboards.build
    @switchboard.show_avatars = true
    @switchboard.entry_width = 2
    @switchboard.reload_interval = 2000
    @switchboard.amount_of_displayed_phone_numbers = 1
    @switchboard.blind_transfer_activated = true
    @switchboard.attended_transfer_activated = false
    spread_breadcrumbs
  end

  def create
    @switchboard = @user.switchboards.build(switchboard_params)
    spread_breadcrumbs
    if @switchboard.save
      redirect_to user_switchboards_path(@user), :notice => t('switchboards.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @switchboard = @user.switchboards.find(params[:id])
    spread_breadcrumbs
  end

  def update
    @switchboard = @user.switchboards.find(params[:id])
    spread_breadcrumbs
    if @switchboard.update_attributes(switchboard_params)
      redirect_to [@user, @switchboard], :notice  => t('switchboards.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @switchboard = @user.switchboards.find(params[:id])
    @switchboard.destroy
    spread_breadcrumbs
    redirect_to user_switchboards_path(@user), :notice => t('switchboards.controller.successfuly_destroyed')
  end

  private
  def switchboard_params
    params.require(:switchboard).permit(:name, :reload_interval, :show_avatars, :entry_width, :amount_of_displayed_phone_numbers, :blind_transfer_activated, :attended_transfer_activated)
  end

  def spread_breadcrumbs
    add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
    add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
    add_breadcrumb t("switchboards.index.page_title"), user_switchboards_path(@user)
    if @switchboard && !@switchboard.new_record?
      add_breadcrumb @switchboard, user_switchboard_path(@user, @switchboard)
    end
  end  
end
