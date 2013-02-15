class SimCardProvidersController < ApplicationController
  load_and_authorize_resource :sim_card_provider
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
  end

  def create
    if @sim_card_provider.save
      redirect_to @sim_card_provider, :notice => t('sim_card_providers.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @sim_card_provider.update_attributes(params[:sim_card_provider])
      redirect_to @sim_card_provider, :notice  => t('sim_card_providers.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @sim_card_provider.destroy
    redirect_to sim_card_providers_url, :notice => t('sim_card_providers.controller.successfuly_destroyed')
  end

  private

  def spread_breadcrumbs
    add_breadcrumb t("sim_card_providers.index.page_title"), sim_card_providers_path
    if @sim_card_provider && !@sim_card_provider.new_record?
      add_breadcrumb @sim_card_provider, sim_card_provider_path(@sim_card_provider)
    end
  end

end
