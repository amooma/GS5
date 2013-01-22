class PhoneBookEntriesController < ApplicationController
  load_and_authorize_resource :phone_book
  load_and_authorize_resource :phone_book_entry, :through => :phone_book, :shallow => true

  before_filter :spread_breadcrumbs
    
  def index
    # In case this is a search params[:q] or params[:name] will contain the query.
    #
    @query = params[:q]
    @query ||= params[:name]
    @query = @query.strip if @query
    
    if !@query.blank?
      if @query.match(/^\+?\d+$/) != nil
        # Find by phone number
        phone_book_entries_ids = @phone_book_entries.map{|entry| entry.id}
        @found_phone_numbers = PhoneNumber.
                where(:phone_numberable_type => 'PhoneBookEntry', :phone_numberable_id => phone_book_entries_ids).
                where('number LIKE ?', "#{@query}%")
        @search_result = @phone_book_entries.where(:id => @found_phone_numbers.map{|entry| entry.phone_numberable_id})
      elsif @query.match(/^[\"\'](.*)[\"\']$/) != nil
        # The User searched for =>'example'<= so he wants an EXACT search for that.
        # This is the fasted and most accurate way of searching.
        # The order to search is: last_name, first_name and organization.
        # It stops searching as soon as it finds results.
        #
        @query = $1
        @search_result = @phone_book_entries.where(:last_name => @query)
        @search_result = @phone_book_entries.where(:first_name => @query) if @search_result.count == 0
        @search_result = @phone_book_entries.where(:organization => @query) if @search_result.count == 0
        
        @exact_search = true
      else
        # Search with SQL LIKE
        #
        @search_result = @phone_book_entries.
                              where( '( ( last_name LIKE ? ) OR ( first_name LIKE ? ) OR ( organization LIKE ? ) )',
                              "#{@query}%", "#{@query}%", "#{@query}%" )
                              
        @exact_search = false
      end

      # Let's have a run with our phonetic search.
      #
      phonetic_query = PhoneBookEntry.koelner_phonetik(@query)
      @phonetic_search_result = @phone_book_entries.where(:last_name_phonetic => phonetic_query)
      @phonetic_search_result = @phone_book_entries.where(:first_name_phonetic => phonetic_query) if @phonetic_search_result.count == 0
      @phonetic_search_result = @phone_book_entries.where(:organization_phonetic => phonetic_query) if @phonetic_search_result.count == 0

      if @phonetic_search_result.count == 0
        # Let's try the search with SQL LIKE. Just in case.
        #
        @phonetic_search_result = @phone_book_entries.where( 'last_name_phonetic LIKE ?', "#{phonetic_query}%" )
        @phonetic_search_result = @phone_book_entries.where( 'first_name_phonetic LIKE ?', "#{phonetic_query}%" ) if @phonetic_search_result.count == 0
        @phonetic_search_result = @phone_book_entries.where( 'organization_phonetic LIKE ?', "#{phonetic_query}%" ) if @phonetic_search_result.count == 0
      end
      
      @phonetic_search = true if @phonetic_search_result.count > 0

      @phone_book_entries = @search_result
      
      if @phone_book_entries.count == 0 && @exact_search == false && @phonetic_search
        @phone_book_entries = @phonetic_search_result
      end
    end
    
    # Let's sort the results and do pagination.
    #
    @phone_book_entries = @phone_book_entries.
                          order([ :last_name, :first_name, :organization ]).
                          paginate(
                            :page => @pagination_page_number,
                            :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
                          )
  end

  def show
  end

  def new
    @phone_book_entry = @phone_book.phone_book_entries.build
    @phone_book_entry.is_male = true
  end

  def create
    @phone_book_entry = @phone_book.phone_book_entries.build( params[:phone_book_entry] )
    if @phone_book_entry.save
      redirect_to phone_book_phone_book_entry_path( @phone_book, @phone_book_entry ), :notice => t('phone_book_entries.controller.successfuly_created', :resource => @phone_book_entry)
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @phone_book_entry.update_attributes(params[:phone_book_entry])
      redirect_to @phone_book_entry, :notice  => t('phone_book_entries.controller.successfuly_updated', :resource => @phone_book_entry)
    else
      render :edit
    end
  end

  def destroy
    @phone_book_entry.destroy
    redirect_to phone_book_entries_url, :notice => t('phone_book_entries.controller.successfuly_destroyed')
  end

  private

  def spread_breadcrumbs
    if @phone_book
      if @phone_book.phone_bookable.class == Tenant
        add_breadcrumb t("phone_books.index.page_title"), tenant_phone_books_path(@phone_book.phone_bookable)
        add_breadcrumb @phone_book, tenant_phone_book_path(@phone_book.phone_bookable, @phone_book)
        add_breadcrumb t("phone_book_entries.index.page_title"), phone_book_phone_book_entries_path(@phone_book)
      end

      if @phone_book.phone_bookable.class == User
        add_breadcrumb t("users.index.page_title"), tenant_users_path(@phone_book.phone_bookable.current_tenant)
        add_breadcrumb @phone_book.phone_bookable, tenant_user_path(@phone_book.phone_bookable.current_tenant, @phone_book.phone_bookable)
        add_breadcrumb t("phone_books.index.page_title"), user_phone_books_path(@phone_book.phone_bookable)
        add_breadcrumb @phone_book, user_phone_book_path(@phone_book.phone_bookable, @phone_book)
        add_breadcrumb t("phone_book_entries.index.page_title"), phone_book_phone_book_entries_path(@phone_book)
      end

      if @phone_book_entry && !@phone_book_entry.new_record?
        add_breadcrumb @phone_book_entry, phone_book_phone_book_entry_path(@phone_book, @phone_book_entry)
      end
    end
  end

end
