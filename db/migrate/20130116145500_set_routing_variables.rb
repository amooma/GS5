class SetRoutingVariables < ActiveRecord::Migration
  def up
    GsParameter.create(:entity => 'call_route', :section => 'failover', :name => '603',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'call_route', :section => 'failover', :name => '480',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'call_route', :section => 'failover', :name => 'UNALLOCATED_NUMBER',  :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:entity => 'call_route', :section => 'failover', :name => 'NORMAL_TEMPORARY_FAILURE',  :value => 'true', :class_type => 'Boolean')
  end

  def down
  	GsParameter.where(:entity => 'call_route', :section => 'failover').destroy_all
  end
end
