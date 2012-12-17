# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.wrappers :tag => :div, :class => :input,
                  :error_class => :field_with_errors do |b|

    # Form extensions
    b.use :html5
    b.optional :pattern
    b.use :maxlength
    b.use :placeholder
    b.use :readonly

    # Form components
    b.use :label_input
    b.use :error, :wrap_with => { :tag => :span, :class => :error }
    b.use :hint,  :wrap_with => { :tag => :span, :class => :hint }
  end

end
