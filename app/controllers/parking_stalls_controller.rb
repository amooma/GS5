class ParkingStallsController < ApplicationController

  load_resource :tenant
  load_resource :user
  load_and_authorize_resource :parking_stall, :through => [:user, :tenant ]
  
  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @parking_stall.lot = 'default'
    @parking_stall.name = ParkingStall.order(:name).last.try(:name).to_i + 1
  end

  def create
    @parking_stall = @parent.parking_stalls.build(params[:parking_stall])
    if @parking_stall.save
      redirect_to [@parent, @parking_stall], :notice => t('parking_stalls.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @parking_stall.update_attributes(params[:parking_stall])
      redirect_to [@parent, @parking_stall], :notice  => t('parking_stalls.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @parking_stall.destroy
    m = method( :"#{@parent.class.name.underscore}_parking_stalls_url" )
    redirect_to m.(@parent), :notice => t('parking_stalls.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @user || @tenant
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @user
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
      add_breadcrumb t("parking_stalls.index.page_title"), user_parking_stalls_path(@user)
      if @parking_stall && !@parking_stall.new_record?
        add_breadcrumb @parking_stall, user_parking_stall_path(@user, @parking_stall)
      end
    end
    if @tenant
      add_breadcrumb t("parking_stalls.index.page_title"), tenant_parking_stalls_path(@tenant)
      if @parking_stall && !@parking_stall.new_record?
        add_breadcrumb @parking_stall, tenant_parking_stall_path(@tenant, @parking_stall)
      end
    end
  end
end
