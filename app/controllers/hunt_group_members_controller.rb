class HuntGroupMembersController < ApplicationController
  load_and_authorize_resource :hunt_group
  load_and_authorize_resource :hunt_group_member, :through => [:hunt_group]

  before_filter :spread_breadcrumbs

  def index
    if params[:active]
      if params[:active].downcase == 'true'
        @hunt_group_members = @hunt_group_members.where(:active => true)
      elsif params[:active].downcase == 'false'
        @hunt_group_members = @hunt_group_members.where(:active => false)
      end
    end
  end

  def show
  end

  def new
    @hunt_group_member = @hunt_group.hunt_group_members.build

    i = @hunt_group.hunt_group_members.count
    loop do
      i += 1
      break unless @hunt_group.hunt_group_members.where(:name => "#{t('hunt_group_members.name')} #{i}").count > 0
    end
    @hunt_group_member.name = "#{t('hunt_group_members.name')} #{i}"
    @hunt_group_member.active = true
    @hunt_group_member.can_switch_status_itself = true
  end

  def create
    @hunt_group_member = @hunt_group.hunt_group_members.build(params[:hunt_group_member])
    if @hunt_group_member.save
      redirect_to hunt_group_hunt_group_member_path(@hunt_group, @hunt_group_member), :notice => t('hunt_group_members.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @hunt_group_member.update_attributes(params[:hunt_group_member])
      redirect_to hunt_group_hunt_group_member_path(@hunt_group, @hunt_group_member), :notice  => t('hunt_group_members.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @hunt_group_member.destroy
    redirect_to hunt_group_hunt_group_members_path(@hunt_group), :notice => t('hunt_group_members.controller.successfuly_destroyed')
  end

  def spread_breadcrumbs
    add_breadcrumb t("hunt_groups.index.page_title"), tenant_hunt_groups_path(@hunt_group.tenant)
    add_breadcrumb @hunt_group, tenant_hunt_group_path(@hunt_group.tenant, @hunt_group)
    add_breadcrumb t("hunt_group_members.index.page_title"), hunt_group_hunt_group_members_path(@hunt_group)
    if @hunt_group_member && !@hunt_group_member.new_record?
      add_breadcrumb @hunt_group_member, hunt_group_hunt_group_member_path(@hunt_group, @hunt_group_member)
    end
  end

end
