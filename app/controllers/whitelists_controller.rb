class WhitelistsController < ApplicationController
  load_and_authorize_resource :callthrough
  load_and_authorize_resource :whitelist, :through => [:callthrough]

  before_filter :set_parent_and_path_methods
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @whitelist.phone_numbers.build
  end

  def create
    @whitelist = @parent.whitelists.build(params[:whitelist])
    if @whitelist.save
      redirect_to @show_path_method.(@parent, @whitelist), :notice => t('whitelists.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @whitelist.update_attributes(params[:whitelist])
      redirect_to @show_path_method.(@parent, @whitelist), :notice  => t('whitelists.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @whitelist.destroy
    redirect_to @index_path_method.(@parent), :notice => t('whitelists.controller.successfuly_destroyed')
  end

  private

  def set_parent_and_path_methods
    @parent = @callthrough
    @show_path_method = method( :"#{@parent.class.name.underscore}_whitelist_path" )
    @index_path_method = method( :"#{@parent.class.name.underscore}_whitelists_path" )
    @new_path_method = method( :"new_#{@parent.class.name.underscore}_whitelist_path" )
    @edit_path_method = method( :"edit_#{@parent.class.name.underscore}_whitelist_path" )
  end

  def spread_breadcrumbs
    if @parent && @parent.class == Callthrough
        add_breadcrumb t("#{@parent.class.name.underscore.pluralize}.name").pluralize, tenant_callthroughs_path(@parent.tenant)
        add_breadcrumb @callthrough, tenant_callthrough_path(@parent.tenant, @callthrough)
        add_breadcrumb t("whitelists.index.page_title"), callthrough_whitelists_path(@parent)
    end
  end

end
