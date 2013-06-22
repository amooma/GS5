class CdrsController < ApplicationController 
  load_and_authorize_resource :tenant

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  helper_method :sort_column, :sort_descending

  def index
    @cdrs = Cdr.order(sort_column + ' ' + (sort_descending ? 'DESC' : 'ASC')).paginate(
      :page => params[:page],
      :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
    )
  end

  def show
  end

  def destroy
    @cdr.destroy
    m = method( :"#{@parent.class.name.underscore}_cdrs_url" )
    redirect_to m.(@parent), :notice => t('cdrs.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @user || @tenant
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    add_breadcrumb t("cdrs.index.page_title"), tenant_cdrs_path(@tenant)
  end

  def sort_descending
    params[:desc].to_s == 'true'
  end

  def sort_column
    Cdr.column_names.include?(params[:sort]) ? params[:sort] : 'start_stamp'
  end

end
