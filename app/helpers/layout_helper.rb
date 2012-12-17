# These helper methods can be called in your template to set
# variables to be used in the layout.
# This module should be included in all views globally,
# to do so you may need to add this line to your
# ApplicationController
#   helper :layout
#
module LayoutHelper
  
  def title( page_title, show_title = true )
    content_for(:title) { strip_tags(page_title.to_s) }
    @show_title = show_title
  end
  
  def show_title?
    @show_title
  end
  
  def stylesheet( *args )
    content_for(:head) { stylesheet_link_tag( *args ) }
  end
  
  def javascript( *args )
    content_for(:head) { javascript_include_tag( *args ) }
  end
  
  def translation_missing?( output )
    (output =~ /span/ or output.empty?)
  end
  
  def conditional_hint( translation_key )
    output = t( translation_key )
    return output unless translation_missing?( output )
    false
  end
  
  def conditional_t( translation_key )
    output = t( translation_key )
    strip_tags( output )
  end
  
  def resolve_flash_sign( type )
    return case type.to_s
      when 'alert'   ; '!'
      when 'warning' ; '!'
      else           ; 'i'
    end
  end
  
  # Returns navigation as an array.
  #
  def navigation_items
    unless @io
      @io = []
      
      if can?( :index, PhoneBookEntry )
        @io << { :url => phone_book_entries_path  , :title => t('phone_book_entries.index.page_title' ) }
      end
      
      # This could be a link to VoiceMails.
      #
      # if can?( :index, Object )
      #   @io << { :url => "#"                      , :title => t('voice_mail') }
      # end
      
    end
    @io
  end
  
end
