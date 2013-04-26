class GenericFilesController < ApplicationController

  load_resource :sip_account
  load_resource :conference
  load_resource :hunt_group
  load_resource :automatic_call_distributor
  load_resource :user
  load_resource :tenant
  load_resource :generic_file

  load_and_authorize_resource :generic_file, :through => [:sip_account, :conference, :hunt_group, :automatic_call_distributor, :user, :tenant]

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  def index
    @generic_files = @parent.generic_files
  end

  def show
    respond_to do |format|
      format.html
      format.xml {render :xml => @generic_file}
      format.all {
        if request.format == @generic_file.file_type
          send_file @generic_file.file.path, :type => @generic_file.file_type, :filename => "#{@generic_file.name}.#{request.parameters[:format].to_s}"
        end
      }
    end
  end

  def new
    @generic_file = @parent.generic_files.build()
  end

  def create
    @generic_file = @parent.generic_files.new(params[:generic_file])
    if @generic_file.save
      m = method( :"#{@parent.class.name.underscore}_generic_files_url" )
      redirect_to m.( @parent ), :notice => t('generic_files.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @generic_file = GenericFile.find(params[:id])
  end

  def update
    @generic_file = GenericFile.find(params[:id])
    if @generic_file.update_attributes(params[:generic_file])
      m = method( :"#{@parent.class.name.underscore}_generic_files_url" )
      redirect_to m.( @parent ), :notice  => t('generic_files.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @generic_file = GenericFile.find(params[:id])
    @generic_file.destroy
    m = method( :"#{@parent.class.name.underscore}_generic_files_url" )
    redirect_to m.( @parent ), :notice => t('generic_files.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @sip_account || @conference || @hunt_group || @automatic_call_distributor || @user || @tenant

    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @parent.class == User
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@parent.current_tenant)
      add_breadcrumb @parent, tenant_user_path(@parent.current_tenant, @parent)
    end

    add_breadcrumb t("generic_files.index.page_title"), method( :"#{@parent.class.name.underscore}_generic_files_url" ).(@parent)

    if !@generic_file.to_s.blank?
      add_breadcrumb @generic_file
    end

  end
end
