class PhoneNumbersController < ApplicationController
  load_resource :phone_book_entry
  load_resource :sip_account
  load_resource :conference
  load_resource :fax_account
  load_resource :phone_number_range
  load_resource :callthrough
  load_resource :whitelist
  load_resource :access_authorization
  load_resource :hunt_group
  load_resource :hunt_group_member
  load_resource :automatic_call_distributor
  load_and_authorize_resource :phone_number, :through => [:phone_book_entry, :sip_account, :conference, 
                                                          :fax_account, :phone_number_range, :callthrough,
                                                          :whitelist, :access_authorization, :hunt_group,
                                                          :hunt_group_member, :automatic_call_distributor]

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
  
  def index
  end

  def show
    @ringtoneable_classes = {
      'SipAccount' => true,
      'HuntGroup' => true,
      'AutomaticCallDistributor' => true,
      'PhoneBookEntry' => true,
    }
    @forwardable_classes = {
      'SipAccount' => true,
      'HuntGroup' => true,
      'AutomaticCallDistributor' => true,
    }
  end

  def new
    @phone_number = @parent.phone_numbers.build()
  end

  def create
    @phone_number = @parent.phone_numbers.new( params[:phone_number] )
    if @phone_number.save
      m = method( :"#{@parent.class.name.underscore}_phone_number_path" )
      redirect_to m.( @parent, @phone_number ), :notice => t('phone_numbers.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @phone_number.update_attributes(params[:phone_number])
      m = method( :"#{@parent.class.name.underscore}_phone_number_path" )
      redirect_to m.( @parent, @phone_number ), :notice  => t('phone_numbers.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @phone_number.destroy
    m = method( :"#{@parent.class.name.underscore}_phone_numbers_url" )
    redirect_to m.(), :notice => t('phone_numbers.controller.successfuly_destroyed')
  end

  def move_higher
    @phone_number.move_higher
    redirect_to :back
  end

  def move_lower
    @phone_number.move_lower
    redirect_to :back
  end

  private
  def set_and_authorize_parent
    @parent = @phone_book_entry || @sip_account || @conference || @fax_account || 
              @phone_number_range || @callthrough || @whitelist || @access_authorization ||
              @hunt_group || @hunt_group_member || @automatic_call_distributor

    authorize! :read, @parent

    @show_path_method = method( :"#{@parent.class.name.underscore}_phone_number_path" )
    @index_path_method = method( :"#{@parent.class.name.underscore}_phone_numbers_path" )
    @new_path_method = method( :"new_#{@parent.class.name.underscore}_phone_number_path" )
    @edit_path_method = method( :"edit_#{@parent.class.name.underscore}_phone_number_path" )
  end

  def spread_breadcrumbs
    if @parent.class == Callthrough
      add_breadcrumb t("#{@parent.class.name.underscore.pluralize}.index.page_title"), tenant_callthroughs_path(@parent.tenant)
      add_breadcrumb @callthrough, tenant_callthrough_path(@parent.tenant, @callthrough)
      add_breadcrumb t("phone_numbers.index.page_title"), callthrough_phone_numbers_path(@parent)
      if @phone_number && !@phone_number.new_record?
        add_breadcrumb @phone_number, callthrough_phone_number_path(@callthrough, @phone_number)
      end
    end

    if @parent.class == SipAccount
     if @sip_account.sip_accountable.class == User
       add_breadcrumb t("#{@sip_account.sip_accountable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore.pluralize}_path" ).(@sip_account.tenant)
       add_breadcrumb @sip_account.sip_accountable, method( :"tenant_#{@sip_account.sip_accountable.class.name.underscore}_path" ).(@sip_account.tenant, @sip_account.sip_accountable)
     end
     add_breadcrumb t("sip_accounts.index.page_title"), method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_accounts_path" ).(@sip_account.sip_accountable)
     add_breadcrumb @sip_account, method( :"#{@sip_account.sip_accountable.class.name.underscore}_sip_account_path" ).(@sip_account.sip_accountable, @sip_account)
     add_breadcrumb t("phone_numbers.index.page_title"), sip_account_phone_numbers_path(@sip_account)
     if @phone_number && !@phone_number.new_record?
       add_breadcrumb @phone_number, sip_account_phone_number_path(@sip_account, @phone_number)
     end
    end

    if @parent.class == Conference
      @conference = @parent
      conference_parent = @conference.conferenceable
      if conference_parent && conference_parent.class == User
        @user = conference_parent
        add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
        add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
        add_breadcrumb t("conferences.index.page_title"), user_conferences_path(@user)
        add_breadcrumb @conference, user_conference_path(@user, @conference)
      end
      if conference_parent && conference_parent.class == Tenant
        @tenant = conference_parent
        add_breadcrumb t("conferences.index.page_title"), tenant_conferences_path(@tenant)
        add_breadcrumb @conference, tenant_conference_path(@tenant, @conference)
      end
      add_breadcrumb t("phone_numbers.index.page_title"), conference_phone_numbers_path(@conference)
      if @phone_number && !@phone_number.new_record?
        add_breadcrumb @phone_number, conference_phone_number_path(@conference, @phone_number)
      end
    end

    if @parent.class == HuntGroup
      add_breadcrumb t("#{@parent.class.name.underscore.pluralize}.index.page_title"), tenant_hunt_groups_path(@parent.tenant)
      add_breadcrumb @hunt_group, tenant_hunt_group_path(@parent.tenant, @hunt_group)
      add_breadcrumb t("phone_numbers.index.page_title"), hunt_group_phone_numbers_path(@parent)
    end

    if @parent.class == HuntGroupMember
      add_breadcrumb t("hunt_groups.index.page_title"), tenant_hunt_groups_path(@parent.hunt_group.tenant)
      add_breadcrumb @parent.hunt_group, tenant_hunt_group_path(@parent.hunt_group.tenant, @parent.hunt_group)
      add_breadcrumb t("hunt_group_members.index.page_title"), hunt_group_hunt_group_members_path(@parent.hunt_group)
      add_breadcrumb @parent, hunt_group_hunt_group_member_path(@parent.hunt_group, @parent)
      add_breadcrumb t("phone_numbers.index.page_title"), hunt_group_member_phone_numbers_path(@parent)
      if @phone_number && !@phone_number.new_record?
        add_breadcrumb @phone_number, hunt_group_member_phone_number_path(@parent, @phone_number)
      end
    end

    if @parent.class == AccessAuthorization
      if @parent.access_authorizationable.class == Callthrough
        callthrough = @parent.access_authorizationable
        tenant = callthrough.tenant
        add_breadcrumb t("callthroughs.index.page_title"), tenant_callthroughs_path(tenant)
        add_breadcrumb callthrough, tenant_callthrough_path(tenant, callthrough)
        add_breadcrumb t("access_authorizations.index.page_title"), callthrough_access_authorizations_path(callthrough)
        add_breadcrumb @parent, callthrough_access_authorization_path(callthrough, @parent)
        add_breadcrumb t("phone_numbers.index.page_title"), access_authorization_phone_numbers_path(@parent)
        if @phone_number && !@phone_number.new_record?
          add_breadcrumb @phone_number, access_authorization_phone_number_path(@parent, @phone_number)
        end
      end
    end

    if @parent.class == PhoneBookEntry
      @phone_book = @parent.phone_book
      if @parent.phone_book.phone_bookable.class == Tenant
        @tenant = @parent.phone_book.phone_bookable
        add_breadcrumb t("phone_books.index.page_title"), tenant_phone_books_path(@tenant)
        add_breadcrumb @phone_book, tenant_phone_book_path(@tenant, @phone_book)
        add_breadcrumb @phone_book_entry, phone_book_phone_book_entry_path(@phone_book, @phone_book_entry)

        if @phone_number && !@phone_number.new_record?
          add_breadcrumb @phone_number, phone_book_entry_phone_number_path(@phone_book_entry, @phone_number)
        end
      end

      if @parent.phone_book.phone_bookable.class == User
        @user = @parent.phone_book.phone_bookable
        add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
        add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
        add_breadcrumb t("phone_books.index.page_title"), user_phone_books_path(@user)
        add_breadcrumb @phone_book, user_phone_book_path(@user, @phone_book)
        add_breadcrumb @phone_book_entry, phone_book_phone_book_entry_path(@phone_book, @phone_book_entry)

        if @phone_number && !@phone_number.new_record?
          add_breadcrumb @phone_number, phone_book_entry_phone_number_path(@phone_book_entry, @phone_number)
        end
      end
    end

    if @parent.class == Whitelist
      @tenant = @parent.whitelistable.tenant
      @callthrough = @parent.whitelistable
      @whitelist = @parent
      add_breadcrumb t("callthroughs.name").pluralize, tenant_callthroughs_path(@tenant)
      add_breadcrumb @callthrough, tenant_callthrough_path(@tenant, @callthrough)
      add_breadcrumb t("whitelists.index.page_title"), callthrough_whitelists_path(@callthrough)
      add_breadcrumb @whitelist, callthrough_whitelist_path(@callthrough, @whitelist)
      add_breadcrumb t("phone_numbers.index.page_title"), whitelist_phone_numbers_path(@whitelist)
      if @phone_number && !@phone_number.new_record?
        add_breadcrumb @phone_number, whitelist_phone_number_path(@whitelist, @phone_number)
      end
    end

    if @parent.class == AutomaticCallDistributor
      if @automatic_call_distributor.automatic_call_distributorable.class == User
        add_breadcrumb t("#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore.pluralize}_path" ).(@automatic_call_distributor.tenant)
        add_breadcrumb @automatic_call_distributor.automatic_call_distributorable, method( :"tenant_#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore}_path" ).(@automatic_call_distributor.tenant, @automatic_call_distributor.automatic_call_distributorable)
      end
      add_breadcrumb t("automatic_call_distributors.index.page_title"), method( :"#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore}_automatic_call_distributors_path" ).(@automatic_call_distributor.automatic_call_distributorable)
      add_breadcrumb @automatic_call_distributor, method( :"#{@automatic_call_distributor.automatic_call_distributorable.class.name.underscore}_automatic_call_distributor_path" ).(@automatic_call_distributor.automatic_call_distributorable, @automatic_call_distributor)
      add_breadcrumb t("phone_numbers.index.page_title"), automatic_call_distributor_phone_numbers_path(@automatic_call_distributor)
      if @phone_number && !@phone_number.new_record?
        add_breadcrumb @phone_number, automatic_call_distributor_phone_number_path(@automatic_call_distributor, @phone_number)
      end
    end

  end

end
