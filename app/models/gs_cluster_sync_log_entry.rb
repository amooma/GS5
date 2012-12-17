class GsClusterSyncLogEntry < ActiveRecord::Base
  attr_accessible :gs_node_id, :class_name, :action, :content, :status, :history, 
                  :homebase_ip_address, :waiting_to_be_synced, :association_method,
                  :association_uuid

  validates :class_name,
            :presence => true

  validates :action,
            :presence => true

  validates :content,
            :presence => true

  after_create :apply_to_local_database

  def apply_to_local_database
    if self.homebase_ip_address != HOMEBASE_IP_ADDRESS
      if self.class_name.constantize.new.attribute_names.include?('is_native')
        case self.action
        when 'create'
          new_local_copy = self.class_name.constantize.new(
                           JSON(self.content).
                           delete_if{|key, value| ['id','updated_at','created_at'].
                           include?(key) }, 
                           :without_protection => true)
          new_local_copy.is_native = false
          find_and_connect_to_an_association(new_local_copy)
          if new_local_copy.save(:validate => false)
            logger.info "Created local copy of #{self.class_name} with the ID #{new_local_copy.id}. #{new_local_copy.to_s}"
          else
            logger.error "Couldn't create a local copy of #{self.class_name} with the ID #{new_local_copy.id}. #{new_local_copy.errors.to_yaml}"
          end

        when 'update'
          local_copy = find_local_copy
          if local_copy
            # Only update an object if the update it self is newer than the local object.
            #
            if local_copy.updated_at < JSON(self.content)['updated_at'].to_time
              local_copy.update_attributes(JSON(self.content).delete_if{|key, value| ['id','updated_at','created_at'].include?(key) }, :without_protection => true)
              find_and_connect_to_an_association(local_copy)
              if local_copy.save(:validate => false)
                logger.info "Updated local copy of #{self.class_name} with the ID #{local_copy.id}. #{local_copy.to_s}"
              else
                logger.error "Couldn't update local copy of #{self.class_name} with the ID #{local_copy.id}. #{local_copy.errors.to_yaml}"
              end
            else
              logger.error "Didn't update local copy of #{self.class_name} with the ID #{local_copy.id} because of a race condition (the local version was newer than the update). Please check GsClusterSyncLogEntry ID #{self.id}."
            end
          else
            logger.error "Couldn't find local copy of #{self.class_name}. #{self.content}"
          end 

        when 'destroy'
          local_copy = find_local_copy
          if local_copy
            local_copy.destroy
            logger.info "Destroyed local copy of #{self.class_name} with the ID #{local_copy.id}. #{local_copy.to_s}"
          else
            logger.error "Couldn't find local copy of #{self.class_name}. #{self.content}"
          end
        end
      else
        logger.error "The class #{self.class_name} doesn't offer the attribute is_native. Can't synchronize without."
      end
    end
  end

  def find_local_copy
    self.class_name.constantize.find_by_uuid(JSON(self.content)['uuid'])
  end

  # Connect to the association (e.g. User to a SipAccount)
  #
  def find_and_connect_to_an_association(local_copy)
    if !(self.association_method.blank? || self.association_uuid.blank?) && (self.association_method_changed? || self.association_uuid_changed?)
      name_of_the_association_type = local_copy.attribute_names.delete_if{|x| !x.include?('_type')}.first
      association = local_copy.send(name_of_the_association_type).constantize.where(:uuid => self.association_uuid).first
      if association
        local_copy.send "#{association_method}=", association
      end
    end
  end

  def populate_other_cluster_nodes
    if self.homebase_ip_address == HOMEBASE_IP_ADDRESS && self.waiting_to_be_synced == true
      if GsNode.where(:push_updates_to => true).count > 0
        GsNode.where(:push_updates_to => true).each do |gs_node|
          RemoteGsNode::GsClusterSyncLogEntry.site = gs_node.site
          remote_enty = RemoteGsNode::GsClusterSyncLogEntry.create(self.attributes.delete_if{|key, value| ['id','updated_at','created_at'].include?(key) })
          self.update_attributes(:waiting_to_be_synced => false)
          self.save
        end
      end
    end
  end
  
end
