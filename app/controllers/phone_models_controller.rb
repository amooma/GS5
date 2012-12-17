class PhoneModelsController < ApplicationController
  load_and_authorize_resource :manufacturer
  load_and_authorize_resource :phone_model, :through => [:manufacturer]
  
  before_filter :spread_breadcrumbs
  
  def index
  end

  def show
  end

  def new
    @phone_model = @manufacturer.phone_models.build
  end

  def create
    @phone_model = @manufacturer.phone_models.build.new(params[:phone_model])
    if @phone_model.save
      redirect_to manufacturer_phone_model_path( @manufacturer, @phone_model ), :notice => t('phone_models.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @phone_model.update_attributes(params[:phone_model])
      redirect_to manufacturer_phone_model_path( @manufacturer, @phone_model ), :notice  => t('phone_models.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @phone_model.destroy
    redirect_to manufacturer_phone_models_url( @manufacturer ), :notice => t('phone_models.controller.successfuly_destroyed')
  end

  private

  def spread_breadcrumbs
    add_breadcrumb t("manufacturers.index.page_title"), manufacturers_path
    add_breadcrumb @manufacturer, manufacturer_path(@manufacturer)
    add_breadcrumb t("phone_models.index.page_title"), manufacturer_phone_models_path(@manufacturer)
    if @phone_model && !@phone_model.new_record?
      add_breadcrumb @phone_model, manufacturer_phone_model_path(@manufacturer, @phone_model)
    end
  end
end
