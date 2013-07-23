class ExtensionModulesController < ApplicationController
  load_resource :phone
  load_and_authorize_resource :extension_module, :through => [:phone]

  before_filter :spread_breadcrumbs

  def index
    @extension_modules = @phone.extension_modules.all
  end

  def show
    @extension_module = @phone.extension_modules.find(params[:id])
  end

  def new
    @extension_module = @phone.extension_modules.build()
  end

  def create
    @extension_module = @phone.extension_modules.build(params[:extension_module])
    if @extension_module.save
      redirect_to phone_extension_module_path(@phone, @extension_module), :notice => t('extension_modules.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @extension_module = @phone.extension_modules.find(params[:id])
  end

  def update
    @extension_module = @phone.extension_modules.find(params[:id])
    if @extension_module.update_attributes(params[:extension_module])
      redirect_to phone_extension_module_path(@phone, @extension_module), :notice  => t('extension_modules.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @extension_module = @phone.extension_modules.find(params[:id])
    @extension_module.destroy
    redirect_to phone_extension_modules_url(@phone), :notice => t('extension_modules.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    if @phone.phoneable.class == User
      add_breadcrumb t('users.index.page_title'), tenant_users_path(@phone.phoneable.current_tenant) 
      add_breadcrumb @phone.phoneable, tenant_user_path(@phone.phoneable.current_tenant, @phone.phoneable) 
      add_breadcrumb t('phones.index.page_title'), user_phones_path(@phone.phoneable) 
    elsif @phone.phoneable.class == Tenant
      add_breadcrumb t('phones.index.page_title'), tenant_phones_path(@phone.phoneable) 
    end

    add_breadcrumb @phone, method( :"#{@phone.phoneable.class.name.underscore}_phone_path" ).(@phone.phoneable, @phone)
    add_breadcrumb t("extension_modules.index.page_title"), phone_extension_modules_path(@phone)

    if @extension_module && !@extension_module.new_record?
      add_breadcrumb @extension_module
    end

  end
end
