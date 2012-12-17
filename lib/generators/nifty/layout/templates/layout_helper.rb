# These helper methods can be called in your template to set variables to be used in the layout
# This module should be included in all views globally,
# to do so you may need to add this line to your ApplicationController
#   helper :layout
module LayoutHelper
  
  def title(page_title, show_title = true)
    content_for(:title) { strip_tags(page_title.to_s) }
    @show_title = show_title
  end

  def show_title?
    @show_title
  end

  def stylesheet(*args)
    content_for(:head) { stylesheet_link_tag(*args) }
  end

  def javascript(*args)
    content_for(:head) { javascript_include_tag(*args) }
  end
  
  def translation_missing?(output)
    (output =~ /span/ or output.empty?)
  end
  
  def conditional_hint(translation_key)
    output = t(translation_key)
    return output unless translation_missing?(output)
    false
  end
  
  def conditional_t(translation_key)
    output = t(translation_key)
    strip_tags(output)
  end
end