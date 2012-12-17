class HuntGroupsController < ApplicationController
  load_and_authorize_resource :tenant
  load_and_authorize_resource :hunt_group, :through => [:tenant]

  before_filter :spread_breadcrumbs

  def index
  end

  def show
  end

  def new
    i = @tenant.hunt_groups.count
    loop do
      i += 1
      break unless @tenant.hunt_groups.where(:name => "#{t('hunt_groups.name')} #{i}").count > 0
    end
    @hunt_group = @tenant.hunt_groups.build(:name => "#{t('hunt_groups.name')} #{i}")
  end

  def create
    @hunt_group = @tenant.hunt_groups.build(params[:hunt_group])
    if @hunt_group.save
      redirect_to tenant_hunt_group_path(@tenant, @hunt_group), :notice => t('hunt_groups.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    @hunt_group = HuntGroup.find(params[:id])
    if @hunt_group.update_attributes(params[:hunt_group])
      redirect_to tenant_hunt_group_path(@tenant, @hunt_group), :notice  => t('hunt_groups.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @hunt_group.destroy
    redirect_to tenant_hunt_groups_path(@tenant), :notice => t('hunt_groups.controller.successfuly_destroyed')
  end

  private
  def spread_breadcrumbs
    add_breadcrumb t("hunt_groups.index.page_title"), tenant_hunt_groups_path(@tenant)
    if @hunt_group && !@hunt_group.new_record?
      add_breadcrumb @hunt_group, tenant_hunt_group_path(@tenant, @hunt_group)
    end
  end
end
