class ManufacturersController < ApplicationController
  load_and_authorize_resource :manufacturer
  
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
  end

  def create
    @manufacturer = Manufacturer.new(params[:manufacturer])
    if @manufacturer.save
      redirect_to @manufacturer, :notice => t('manufacturers.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @manufacturer.update_attributes(params[:manufacturer])
      redirect_to @manufacturer, :notice  => t('manufacturers.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @manufacturer.destroy
    redirect_to manufacturers_url, :notice => t('manufacturers.controller.successfuly_destroyed')
  end

  private

  def spread_breadcrumbs
    add_breadcrumb t("manufacturers.index.page_title"), manufacturers_path
    if @manufacturer && !@manufacturer.new_record?
      add_breadcrumb @manufacturer, manufacturer_path(@manufacturer)
    end
  end

end
