class ActiveRecord::Base

  before_validation :populate_uuid, :on => :create
  before_validation :populate_gs_node_id, :on => :create

  # Set a UUID.
  #
  def populate_uuid
    if self.attribute_names.include?('uuid') && self.uuid.blank?
      uuid = UUID.new
      self.uuid = uuid.generate
    end
  end

  # Set the gs_node_id if not already set.
  #
  def populate_gs_node_id
    if self.attribute_names.include?('gs_node_id') && self.gs_node_id.blank? 
      self.gs_node_id = GsNode.where(:ip_address => HOMEBASE_IP_ADDRESS).first.try(:id)
    end 
  end

  # Create a new GsClusterSyncLogEntry.
  # This will be populated automatically to GsNode.all.where(...)
  # 
  def create_on_other_gs_nodes(association_method = nil, association_uuid = nil)
    action_on_other_gs_nodes('create', self.to_json, nil, association_method, association_uuid)
  end

  def destroy_on_other_gs_nodes
    action_on_other_gs_nodes('destroy', self.to_json)
  end

  def update_on_other_gs_nodes(association_method = nil, association_uuid = nil)
    action_on_other_gs_nodes('update', self.changes.to_json, 'Changed: ' + self.changed.to_json, association_method, association_uuid)
  end

  def action_on_other_gs_nodes(action, content, history = nil, association_method = nil, association_uuid = nil)
    # One doesn't make sense without the other.
    #
    if association_method.blank? || association_uuid.blank?
      association_method = nil
      association_uuid = nil
    end
    history = nil if history.blank?
    if !self.attribute_names.include?('is_native')
      logger.error "Couldn't #{action} #{self.class} with the ID #{self.id} on other GsNodes because #{self.class} doesn't have a is_native attribute."
    else
      if self.is_native != false
        if defined? WRITE_GS_CLUSTER_SYNC_LOG && WRITE_GS_CLUSTER_SYNC_LOG == true
          if !(defined? $gs_cluster_loop_protection) || $gs_cluster_loop_protection != true
            begin
              GsClusterSyncLogEntry.create(
                                          :class_name => self.class.name,
                                          :action => action,
                                          :content => content,
                                          :history => history,
                                          :homebase_ip_address => HOMEBASE_IP_ADDRESS,
                                          :waiting_to_be_synced => true,
                                          :association_method => association_method,
                                          :association_uuid => association_uuid
                                        )
            rescue
              logger.error "Couldn't add action: #{action} for #{self.class} with the ID #{self.id} to gs_cluster_log_entries."
            end
          end
        end
      end
    end
  end

end