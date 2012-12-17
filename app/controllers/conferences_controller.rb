class ConferencesController < ApplicationController
  load_resource :user
  load_resource :tenant
  load_and_authorize_resource :conference, :through => [:user, :tenant]
  
  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
  
  def index
  end

  def show
    @phone_numbers = @conference.phone_numbers
  end

  def new
    @conference = @parent.conferences.build
    @conference.name = generate_a_new_name(@parent, @conference)
    @conference.start = nil
    @conference.end = nil
    @conference.open_for_anybody = true
    @conference.max_members = DEFAULT_MAX_CONFERENCE_MEMBERS
    @conference.pin = random_pin

    @conference.open_for_anybody = true
    @conference.announce_new_member_by_name = true
    @conference.announce_left_member_by_name = true
  end

  def create
    @conference = @parent.conferences.build(params[:conference])
    if @conference.save
      m = method( :"#{@parent.class.name.underscore}_conference_path" )
      redirect_to m.( @parent, @conference ), :notice => t('conferences.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @conference.update_attributes(params[:conference])
      m = method( :"#{@parent.class.name.underscore}_conference_path" )
      redirect_to m.( @parent, @conference ), :notice => t('conferences.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @conference.destroy
    m = method( :"#{@parent.class.name.underscore}_conferences_url" )
    redirect_to m.( @parent ), :notice => t('conferences.controller.successfuly_destroyed')
  end
  
  private

  def set_and_authorize_parent
    @parent = @tenant || @user
    authorize! :read, @parent
  end
  
  def spread_breadcrumbs
    if @parent && @parent.class == User
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
      add_breadcrumb t("conferences.index.page_title"), user_conferences_path(@user)
      if @conference && !@conference.new_record?
        add_breadcrumb @conference, user_conference_path(@user, @conference)
      end
    end
    if @parent && @parent.class == Tenant
      add_breadcrumb t("conferences.index.page_title"), tenant_conferences_path(@tenant)
      if @conference && !@conference.new_record?
        add_breadcrumb @conference, tenant_conference_path(@tenant, @conference)
      end
    end
  end

end
