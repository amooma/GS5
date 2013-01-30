class AddNoCopyHeaders < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'dialplan', :section => 'variables', :name => 'sip_copy_custom_headers', :value => 'false', :class_type => 'Boolean', :description => 'Controls passing SIP headers from one call leg to another.')
  end

  def down
  	GsParameter.create(:entity => 'dialplan', :section => 'variables', :name => 'sip_copy_custom_headers').destroy_all
  end
end
