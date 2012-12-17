class ConferenceInviteesController < ApplicationController
  load_and_authorize_resource :conference
  load_and_authorize_resource :conference_invitee, :through => [:conference]
  
  before_filter :spread_breadcrumbs

  def index
  end
  
  def show
  end

  def new
    @conference_invitee = @conference.conference_invitees.build
    @conference_invitee.speaker = true
    @conference_invitee.moderator = false
    @phone_number = @conference_invitee.build_phone_number
  end

  def create
    @conference_invitee = @conference.conference_invitees.build(params[:conference_invitee])

    # Try to find this phone_number in phone_books the current_user can read.
    # Save the found entry as phone_book_entry.
    #
    @conference_invitee.phone_number.parse_and_split_number!
    phone_numbers = PhoneNumber.where(:number => @conference_invitee.phone_number.number).
                                where(:phone_numberable_type => 'PhoneBookEntry')
    phone_numbers.each do |phone_number|
      phone_book = phone_number.phone_numberable.phone_book
      if can?(:read, phone_book)
        @conference_invitee.phone_book_entry = phone_number.phone_numberable
        break
      end
    end                            
    
    if @conference_invitee.save
      # m = method( :"#{@parent_in_route.class.name.underscore}_path" )
      # redirect_to m.( @parent_in_route ), :notice => t('conference_invitees.controller.successfuly_created', :resource => @conference_invitees)
      m = method( :"#{@conference_invitee.conference.conferenceable_type.underscore}_conference_path")
      redirect_to m.( @conference_invitee.conference.conferenceable, @conference_invitee.conference), :notice => t('conference_invitees.controller.successfuly_created', :resource => @conference_invitees)
    else
      render :new
    end
  end

  def edit
    authorize! :edit, @parent_in_route
  end

  def update
    if @conference_invitee.update_attributes(params[:conference_invitee])
      redirect_to @conference_invitee, :notice  => t('conference_invitees.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @conference_invitee.destroy
    redirect_to conference_invitees_url, :notice => t('conference_invitees.controller.successfuly_destroyed')
  end

  private

  def spread_breadcrumbs
    if @conference
      @parent = @conference.conferenceable
      if @parent && @parent.class == User
        @user = @parent
        add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
        add_breadcrumb @user, tenant_users_path(@user.current_tenant, @user)
        add_breadcrumb t("conferences.index.page_title"), user_conferences_path(@user)
        if @conference && !@conference.new_record?
          add_breadcrumb @conference, user_conference_path(@user, @conference)
        end
      end
      if @parent && @parent.class == Tenant
        @tenant = @parent
        add_breadcrumb t("conferences.index.page_title"), tenant_conferences_path(@tenant)
        if @conference && !@conference.new_record?
          add_breadcrumb @conference, tenant_conference_path(@tenant, @conference)
        end
      end

      add_breadcrumb t("conference_invitees.index.page_title"), conference_conference_invitees_path(@conference)
      if @conference_invitee && !@conference_invitee.new_record?
        add_breadcrumb @conference_invitee, conference_conference_invitee_path(@conference, @conference_invitee)
      end
    end
  end

end
