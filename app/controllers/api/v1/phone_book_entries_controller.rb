module Api
  module V1
    class PhoneBookEntriesController < ApplicationController
      respond_to :json

      def index
        query = params[:query]
        
        return nil if query.blank?

        current_ability = Ability.new(current_user)
        phone_book_entries = PhoneBookEntry.accessible_by(current_ability)

        if query.match(/^\+?\d+$/) != nil
          # Find by phone number
          phone_book_entries_ids = phone_book_entries.map{|entry| entry.id}
          found_phone_numbers = PhoneNumber.
                  where(:phone_numberable_type => 'PhoneBookEntry', :phone_numberable_id => phone_book_entries_ids).
                  where('number LIKE ?', "#{query}%")
          search_result = phone_book_entries.where(:id => found_phone_numbers.map{|entry| entry.phone_numberable_id})
        elsif query.match(/^[\"\'](.*)[\"\']$/) != nil
          # The User searched for =>'example'<= so he wants an EXACT search for that.
          # This is the fasted and most accurate way of searching.
          # The order to search is: last_name, first_name and organization.
          # It stops searching as soon as it finds results.
          #
          query = $1
          search_result = phone_book_entries.where(:last_name => query)
          search_result = phone_book_entries.where(:first_name => query) if search_result.blank?
          search_result = phone_book_entries.where(:organization => query) if search_result.blank?
          
          exact_search = true
        else
          # Search with SQL LIKE
          #
          search_result = phone_book_entries.
                                where( '( ( last_name LIKE ? ) OR ( first_name LIKE ? ) OR ( organization LIKE ? ) )',
                                "#{query}%", "#{query}%", "#{query}%" )
                                
          exact_search = false
        end

        # Let's have a run with our phonetic search.
        #
        phonetic_query = PhoneBookEntry.koelner_phonetik(query)
        phonetic_search_result = phone_book_entries.where(:last_name_phonetic => phonetic_query)
        phonetic_search_result = phone_book_entries.where(:first_name_phonetic => phonetic_query) if phonetic_search_result.blank?
        phonetic_search_result = phone_book_entries.where(:organization_phonetic => phonetic_query) if phonetic_search_result.blank?

        if phonetic_search_result.blank?
          # Let's try the search with SQL LIKE. Just in case.
          #
          phonetic_search_result = phone_book_entries.where( 'last_name_phonetic LIKE ?', "#{phonetic_query}%" )
          phonetic_search_result = phone_book_entries.where( 'first_name_phonetic LIKE ?', "#{phonetic_query}%" ) if phonetic_search_result.blank?
          phonetic_search_result = phone_book_entries.where( 'organization_phonetic LIKE ?', "#{phonetic_query}%" ) if phonetic_search_result.blank?
        end
        
        phonetic_search = true if phonetic_search_result.any?

        phone_book_entries = search_result
        
        if phone_book_entries.count == 0 && exact_search == false && phonetic_search
          phone_book_entries = phonetic_search_result
        end
        
        # Let's sort the results and do pagination.
        #
        phone_book_entries = phone_book_entries.
                              order([ :last_name, :first_name, :organization ])

        respond_with phone_book_entries
      end
 
    end
  end
end
