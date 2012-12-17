class AccessAuthorizationsController < ApplicationController
  load_and_authorize_resource :callthrough
  load_and_authorize_resource :access_authorization, :through => [:callthrough]

  before_filter :set_parent_and_path_methods
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @access_authorization = @parent.access_authorizations.build
    @access_authorization.name = generate_a_new_name(@parent, @access_authorization)
    @access_authorization.phone_numbers.build
    @access_authorization.login = random_pin + random_pin
    @access_authorization.pin = random_pin
  end

  def create
    @access_authorization = @parent.access_authorizations.build(params[:access_authorization])
    if @access_authorization.save
      redirect_to @show_path_method.(@parent, @access_authorization), :notice => t('access_authorizations.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @access_authorization.update_attributes(params[:access_authorization])
      redirect_to @show_path_method.(@parent, @access_authorization), :notice  => t('access_authorizations.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @access_authorization.destroy
    redirect_to @index_path_method.(@parent), :notice => t('access_authorizations.controller.successfuly_destroyed')
  end

  private

  def set_parent_and_path_methods
    @parent = @callthrough
    @show_path_method = method( :"#{@parent.class.name.underscore}_access_authorization_path" )
    @index_path_method = method( :"#{@parent.class.name.underscore}_access_authorizations_path" )
    @new_path_method = method( :"new_#{@parent.class.name.underscore}_access_authorization_path" )
    @edit_path_method = method( :"edit_#{@parent.class.name.underscore}_access_authorization_path" )
  end

  def spread_breadcrumbs
    if @callthrough
      add_breadcrumb t("#{@parent.class.name.underscore.pluralize}.index.page_title"), tenant_callthroughs_path(@callthrough.tenant)
      add_breadcrumb @callthrough, tenant_callthrough_path(@callthrough.tenant, @callthrough)
      add_breadcrumb t("access_authorizations.index.page_title"), callthrough_access_authorizations_path(@callthrough)
      if @access_authorization && !@access_authorization.new_record?
        add_breadcrumb @access_authorization, callthrough_access_authorization_path(@callthrough, @access_authorization)
      end
    end
  end

end
