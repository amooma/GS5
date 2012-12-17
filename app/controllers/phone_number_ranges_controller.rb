class PhoneNumberRangesController < ApplicationController
  load_and_authorize_resource :tenant
  load_and_authorize_resource :phone_number_range, :through => [:tenant]
  
  before_filter :set_parent
  before_filter :spread_breadcrumbs
  
  def index
  end

  def show
  end

  def new
    @phone_number_range = @parent.phone_number_ranges.build
  end

  def create
    @phone_number_range = @parent.phone_number_ranges.build(params[:phone_number_range])
    if @phone_number_range.save
      redirect_to @phone_number_range, :notice => t('phone_number_ranges.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @phone_number_range.update_attributes(params[:phone_number_range])
      redirect_to @phone_number_range, :notice  => t('phone_number_ranges.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @phone_number_range.destroy
    redirect_to phone_number_ranges_url, :notice => t('phone_number_ranges.controller.successfuly_destroyed')
  end
  
  private

  def set_parent
    @parent = @tenant
  end

  def spread_breadcrumbs
    add_breadcrumb t("phone_number_ranges.index.page_title"), tenant_phone_number_ranges_path(@tenant)
    if @phone_number_range && !@phone_number_range.new_record?
      add_breadcrumb t("phone_number_ranges.ranges.#{@phone_number_range}.label"), tenant_phone_number_range_path(@tenant, @phone_number_range)
    end
  end
  
end
