class ChangePerimeterGsParameters < ActiveRecord::Migration
  def up
    GsParameter.find_or_create_by_entity_and_section_and_name('perimeter', 'bad_headers_register', 'from_user').update_attributes(:value => '^%d+$', :class_type => 'String')
    GsParameter.where(:entity => 'perimeter', :section => 'bad_headers_register', :name => 'to_user').first.update_attributes(:value => '^%d+$', :class_type => 'String')
    
    GsParameter.where(:entity => 'perimeter', :section => 'checks_call', :name => 'check_bad_headers').first.update_attributes(:value => '20', :class_type => 'Integer')
    GsParameter.where(:entity => 'perimeter', :section => 'checks_call', :name => 'check_frequency').first.update_attributes(:value => '100', :class_type => 'Integer')
    
    GsParameter.where(:entity => 'perimeter', :section => 'checks_register', :name => 'check_bad_headers').first.update_attributes(:value => '20', :class_type => 'Integer')
    GsParameter.where(:entity => 'perimeter', :section => 'checks_register', :name => 'check_frequency').first.update_attributes(:value => '100', :class_type => 'Integer')
    GsParameter.where(:entity => 'perimeter', :section => 'checks_register', :name => 'check_username_scan').first.update_attributes(:value => '20', :class_type => 'Integer')

    GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'ban_threshold').first.update_attributes(:value => '1000', :class_type => 'Integer')
  end

  def down
  end
end
