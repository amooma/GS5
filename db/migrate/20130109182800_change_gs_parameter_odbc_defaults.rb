class ChangeGsParameterOdbcDefaults < ActiveRecord::Migration
  def up
    GsParameter.where(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'odbc-dsn').destroy_all
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'odbc-dsn',  :value => 'default', :class_type => 'String')
  end

  def down
    GsParameter.where(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'odbc-dsn').destroy_all
    GsParameter.create(:entity => 'sofia', :section => 'profile:gemeinschaft', :name => 'odbc-dsn',  :value => 'gemeinschaft:gemeinschaft:gemeinschaft', :class_type => 'String')
  end
end
