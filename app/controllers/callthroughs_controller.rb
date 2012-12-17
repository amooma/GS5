class CallthroughsController < ApplicationController
  load_and_authorize_resource :tenant
  load_and_authorize_resource :callthrough, :through => [:tenant]

  before_filter :set_parent_and_path_methods
  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    @callthrough = @tenant.callthroughs.build
    @callthrough.name = generate_a_new_name(@tenant, @callthrough)
    @callthrough.phone_numbers.build
    @callthrough.access_authorizations.build(:name => "#{t('access_authorizations.name')} #{@callthrough.access_authorizations.count + 1}", :pin => random_pin).phone_numbers.build
    @callthrough.whitelists.build.phone_numbers.build
  end

  def create
    @callthrough = @tenant.callthroughs.build(params[:callthrough])
    if @callthrough.save
      redirect_to tenant_callthrough_path(@tenant, @callthrough), :notice => t('callthroughs.controller.successfuly_created')
    else
      @callthrough.phone_numbers.build if @callthrough.phone_numbers.size == 0
      render :new
    end
  end

  def edit
    @callthrough.phone_numbers.build
    @callthrough.access_authorizations.build.phone_numbers.build
    if @callthrough.whitelisted_phone_numbers.count == 0
     if @callthrough.whitelists.count == 0
       @callthrough.whitelists.build.phone_numbers.build 
     else
       @callthrough.whitelists.first.phone_numbers.build
     end      
    end
  end

  def update
    if @callthrough.update_attributes(params[:callthrough])
      redirect_to tenant_callthrough_path(@tenant, @callthrough), :notice  => t('callthroughs.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @callthrough.destroy
    redirect_to tenant_callthroughs_path(@tenant), :notice => t('callthroughs.controller.successfuly_destroyed')
  end

  private

  def set_parent_and_path_methods
    @parent = @tenant
    @show_path_method = method( :"#{@parent.class.name.underscore}_callthrough_path" )
    @index_path_method = method( :"#{@parent.class.name.underscore}_callthroughs_path" )
    @new_path_method = method( :"new_#{@parent.class.name.underscore}_callthrough_path" )
    @edit_path_method = method( :"edit_#{@parent.class.name.underscore}_callthrough_path" )
  end

  def spread_breadcrumbs
    if @parent && @parent.class == Tenant
      add_breadcrumb t("callthroughs.name").pluralize, tenant_callthroughs_path(@parent)
      if @callthrough && !@callthrough.new_record?
        add_breadcrumb @callthrough, tenant_callthrough_path(@parent, @callthrough)
      end
    end
  end
end
