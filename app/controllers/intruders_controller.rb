class IntrudersController < ApplicationController
  load_and_authorize_resource :intruder
  
  def index
    @intruders = Intruder.order('list_type ASC, contact_last DESC')
    @list_types = @intruders.pluck(:list_type).uniq.sort
    spread_breadcrumbs
  end

  def show
    @intruder = Intruder.find(params[:id])
    if ! params[:whois].blank?
      @whois = @intruder.whois(params[:whois])
    end
    spread_breadcrumbs
  end

  def new
    @intruder = Intruder.new
    spread_breadcrumbs
  end

  def create
    @intruder = Intruder.new(params[:intruder])
    spread_breadcrumbs
    if @intruder.save
      redirect_to @intruder, :notice => t('intruders.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @intruder = Intruder.find(params[:id])
    spread_breadcrumbs
  end

  def update
    @intruder = Intruder.find(params[:id])
    spread_breadcrumbs
    if @intruder.update_attributes(params[:intruder])
      redirect_to @intruder, :notice  => t('intruders.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @intruder = Intruder.find(params[:id])
    spread_breadcrumbs
    @intruder.destroy
    redirect_to intruders_url, :notice => t('intruders.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("intruders.index.page_title"), intruders_path
    if @intruder && !@intruder.new_record?
      add_breadcrumb @intruder, @intruder
    end
  end
end
