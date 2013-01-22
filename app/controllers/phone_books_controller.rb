class PhoneBooksController < ApplicationController
  load_resource :user
  load_resource :user_group
  load_resource :tenant
  load_and_authorize_resource :phone_book, :through => [:user, :user_group, :tenant]

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs
 
  def index
  end

  def show
    @by_name = params[:name]
    
    @pagination_page_number = params[:page].to_i
    @pagination_page_number = 1 if @pagination_page_number < 1
    
    if @by_name.blank?
      @phone_book_entries = @phone_book.
                            phone_book_entries.
                            order([ :last_name, :first_name ]).
                            paginate(
                              :page => @pagination_page_number,
                              :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
                            )
    else
      # search by name
      @by_name = @by_name.
        gsub( /[^A-Za-z0-9#]/, '' ).
        gsub('*','?').
        gsub('%','_').
        gsub(/^#/,'').
        upcase
      
      @phone_book_entries = @phone_book.
                            phone_book_entries.
                            where( '( ( last_name LIKE ? ) OR ( first_name LIKE ? ) )', "#{@by_name}%", "#{@by_name}%" ).
                            order([ :last_name, :first_name ]).
                            paginate(
                              :page => @pagination_page_number,
                              :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
                            )
    end
  end

  def new
    @phone_book = @parent.phone_books.build
    @phone_book.name = generate_a_new_name(@parent, @phone_book)
  end

  def create
    @phone_book = @parent.phone_books.build( params[:phone_book] )
    if @phone_book.save
      m = method( :"#{@parent.class.name.underscore}_phone_book_path" )
      redirect_to m.( @parent, @phone_book ), :notice => t('phone_books.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @phone_book.update_attributes(params[:phone_book])
      m = method( :"#{@parent.class.name.underscore}_phone_book_path" )
      redirect_to m.( @parent, @phone_book ), :notice  => t('phone_books.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @phone_book.destroy
    m = method( :"#{@parent.class.name.underscore}_phone_books_url" )
    redirect_to m.( @parent ), :notice => t('phone_books.controller.successfuly_destroyed')
  end

  private
  def set_and_authorize_parent
    @parent = @user || @user_group || @tenant
    authorize! :read, @parent
  end

  def spread_breadcrumbs
    if @parent.class == Tenant
      add_breadcrumb t("phone_books.index.page_title"), tenant_phone_books_path(@tenant)
      if @phone_book && !@phone_book.new_record?
        add_breadcrumb @phone_book, tenant_phone_book_path(@tenant, @phone_book)
      end
    end

    if @parent.class == User
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@user.current_tenant)
      add_breadcrumb @user, tenant_user_path(@user.current_tenant, @user)
      add_breadcrumb t("phone_books.index.page_title"), user_phone_books_path(@user)
      if @phone_book && !@phone_book.new_record?
        add_breadcrumb @phone_book, user_phone_book_path(@user, @phone_book)
      end
    end

  end

end
