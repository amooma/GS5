# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130212071000) do

  create_table "access_authorizations", :force => true do |t|
    t.string   "access_authorizationable_type"
    t.integer  "access_authorizationable_id"
    t.string   "name"
    t.string   "login"
    t.string   "pin"
    t.integer  "position"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "sip_account_id"
    t.string   "uuid"
  end

  add_index "access_authorizations", ["uuid"], :name => "index_access_authorizations_on_uuid"

  create_table "acd_agents", :force => true do |t|
    t.string   "uuid"
    t.string   "name"
    t.string   "status"
    t.integer  "automatic_call_distributor_id"
    t.datetime "last_call"
    t.integer  "calls_answered"
    t.string   "destination_type"
    t.integer  "destination_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "acd_callers", :force => true do |t|
    t.string   "channel_uuid"
    t.integer  "automatic_call_distributor_id"
    t.string   "status"
    t.datetime "enter_time"
    t.datetime "agent_answer_time"
    t.string   "callback_number"
    t.integer  "callback_attempts"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "addresses", :force => true do |t|
    t.integer  "phone_book_entry_id"
    t.string   "line1"
    t.string   "line2"
    t.string   "street"
    t.string   "zip_code"
    t.string   "city"
    t.integer  "country_id"
    t.integer  "position"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "uuid"
  end

  create_table "aliases", :id => false, :force => true do |t|
    t.integer "sticky"
    t.string  "alias",    :limit => 128
    t.string  "command",  :limit => 4096
    t.string  "hostname", :limit => 256
  end

  add_index "aliases", ["alias"], :name => "alias1"

  create_table "api_rows", :force => true do |t|
    t.string   "user_id"
    t.string   "user_name"
    t.string   "last_name"
    t.string   "middle_name"
    t.string   "first_name"
    t.string   "office_phone_number"
    t.string   "internal_extension"
    t.string   "mobile_phone_number"
    t.string   "fax_phone_number"
    t.string   "email"
    t.string   "pin"
    t.datetime "pin_updated_at"
    t.string   "photo_file_name"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "area_codes", :force => true do |t|
    t.integer  "country_id"
    t.string   "name"
    t.string   "area_code"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "central_office_code"
  end

  create_table "automatic_call_distributors", :force => true do |t|
    t.string   "uuid"
    t.string   "name"
    t.string   "strategy"
    t.string   "automatic_call_distributorable_type"
    t.integer  "automatic_call_distributorable_id"
    t.integer  "max_callers"
    t.integer  "agent_timeout"
    t.integer  "retry_timeout"
    t.string   "join"
    t.string   "leave"
    t.integer  "gs_node_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.integer  "announce_position"
    t.string   "announce_call_agents"
    t.string   "greeting"
    t.string   "goodbye"
    t.string   "music"
  end

  create_table "backup_jobs", :force => true do |t|
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string   "state"
    t.string   "directory"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "backup_file"
  end

  create_table "call_forward_cases", :force => true do |t|
    t.string   "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "call_forward_cases", ["value"], :name => "call_forward_cases_value_index", :unique => true

  create_table "call_forwards", :force => true do |t|
    t.integer  "call_forward_case_id"
    t.integer  "timeout"
    t.string   "destination"
    t.string   "source"
    t.boolean  "active"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "phone_number_id"
    t.integer  "depth"
    t.string   "call_forwardable_type"
    t.integer  "call_forwardable_id"
    t.integer  "position"
    t.string   "uuid"
  end

  add_index "call_forwards", ["phone_number_id"], :name => "index_call_forwards_on_phone_number_id"

  create_table "call_histories", :force => true do |t|
    t.string   "call_historyable_type"
    t.integer  "call_historyable_id"
    t.string   "entry_type"
    t.string   "caller_account_type"
    t.integer  "caller_account_id"
    t.string   "caller_id_number"
    t.string   "caller_id_name"
    t.string   "caller_channel_uuid"
    t.string   "callee_account_type"
    t.integer  "callee_account_id"
    t.string   "callee_id_number"
    t.string   "callee_id_name"
    t.string   "auth_account_type"
    t.integer  "auth_account_id"
    t.string   "forwarding_service"
    t.string   "destination_number"
    t.datetime "start_stamp"
    t.integer  "duration"
    t.string   "result"
    t.boolean  "read_flag"
    t.boolean  "returned_flag"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "call_routes", :force => true do |t|
    t.string   "routing_table"
    t.string   "name"
    t.string   "endpoint_type"
    t.integer  "endpoint_id"
    t.integer  "position"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "calls", :id => false, :force => true do |t|
    t.string  "call_uuid"
    t.string  "call_created",                  :limit => 128
    t.integer "call_created_epoch"
    t.string  "function",                      :limit => 1024
    t.string  "caller_cid_name",               :limit => 1024
    t.string  "caller_cid_num",                :limit => 256
    t.string  "caller_dest_num",               :limit => 256
    t.string  "caller_chan_name",              :limit => 1024
    t.string  "caller_uuid",                   :limit => 256
    t.string  "callee_cid_name",               :limit => 1024
    t.string  "callee_cid_numcallee_dest_num", :limit => 256
    t.string  "callee_chan_name",              :limit => 1024
    t.string  "callee_uuid",                   :limit => 256
    t.string  "hostname",                      :limit => 256
  end

  add_index "calls", ["call_uuid", "hostname"], :name => "eeuuindex2"
  add_index "calls", ["callee_uuid", "hostname"], :name => "eeuuindex"
  add_index "calls", ["caller_uuid", "hostname"], :name => "eruuindex"
  add_index "calls", ["hostname"], :name => "calls1"

  create_table "callthroughs", :force => true do |t|
    t.integer  "tenant_id"
    t.string   "name"
    t.string   "clip_no_screening"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.string   "uuid"
  end

  create_table "cdrs", :id => false, :force => true do |t|
    t.string   "uuid",                    :limit => 256
    t.integer  "account_id"
    t.string   "account_type",            :limit => 256
    t.string   "bleg_uuid",               :limit => 256
    t.integer  "bleg_account_id"
    t.string   "bleg_account_type",       :limit => 256
    t.string   "dialed_number",           :limit => 256
    t.string   "destination_number",      :limit => 256
    t.string   "caller_id_number",        :limit => 256
    t.string   "caller_id_name",          :limit => 256
    t.string   "callee_id_number",        :limit => 256
    t.string   "callee_id_name",          :limit => 256
    t.datetime "start_stamp"
    t.datetime "answer_stamp"
    t.datetime "end_stamp"
    t.integer  "duration"
    t.integer  "billsec"
    t.string   "hangup_cause",            :limit => 256
    t.string   "dialstatus",              :limit => 256
    t.string   "forwarding_number",       :limit => 256
    t.integer  "forwarding_account_id"
    t.string   "forwarding_account_type", :limit => 256
    t.string   "forwarding_service",      :limit => 256
    t.datetime "bleg_read_time"
    t.datetime "forwarding_read_time"
    t.datetime "bridge_stamp"
  end

  create_table "channels", :id => false, :force => true do |t|
    t.string  "uuid",             :limit => 256
    t.string  "direction",        :limit => 32
    t.string  "created",          :limit => 128
    t.integer "created_epoch"
    t.string  "name",             :limit => 1024
    t.string  "state",            :limit => 64
    t.string  "cid_name",         :limit => 1024
    t.string  "cid_num",          :limit => 256
    t.string  "ip_addr",          :limit => 256
    t.string  "dest",             :limit => 1024
    t.string  "application",      :limit => 128
    t.string  "application_data", :limit => 4096
    t.string  "dialplan",         :limit => 128
    t.string  "context",          :limit => 128
    t.string  "read_codec",       :limit => 128
    t.string  "read_rate",        :limit => 32
    t.string  "read_bit_rate",    :limit => 32
    t.string  "write_codec",      :limit => 128
    t.string  "write_rate",       :limit => 32
    t.string  "write_bit_rate",   :limit => 32
    t.string  "secure",           :limit => 32
    t.string  "hostname",         :limit => 256
    t.string  "presence_id",      :limit => 4096
    t.string  "presence_data",    :limit => 4096
    t.string  "callstate",        :limit => 64
    t.string  "callee_name",      :limit => 1024
    t.string  "callee_num",       :limit => 256
    t.string  "callee_direction", :limit => 5
    t.string  "call_uuid",        :limit => 256
  end

  add_index "channels", ["call_uuid", "hostname"], :name => "uuindex2"
  add_index "channels", ["hostname"], :name => "channels1"
  add_index "channels", ["uuid", "hostname"], :name => "uuindex", :unique => true

  create_table "complete", :id => false, :force => true do |t|
    t.integer "sticky"
    t.string  "a1",       :limit => 128
    t.string  "a2",       :limit => 128
    t.string  "a3",       :limit => 128
    t.string  "a4",       :limit => 128
    t.string  "a5",       :limit => 128
    t.string  "a6",       :limit => 128
    t.string  "a7",       :limit => 128
    t.string  "a8",       :limit => 128
    t.string  "a9",       :limit => 128
    t.string  "a10",      :limit => 128
    t.string  "hostname", :limit => 256
  end

  add_index "complete", ["a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "hostname"], :name => "complete11"
  add_index "complete", ["a1", "hostname"], :name => "complete1"
  add_index "complete", ["a10", "hostname"], :name => "complete10"
  add_index "complete", ["a2", "hostname"], :name => "complete2"
  add_index "complete", ["a3", "hostname"], :name => "complete3"
  add_index "complete", ["a4", "hostname"], :name => "complete4"
  add_index "complete", ["a5", "hostname"], :name => "complete5"
  add_index "complete", ["a6", "hostname"], :name => "complete6"
  add_index "complete", ["a7", "hostname"], :name => "complete7"
  add_index "complete", ["a8", "hostname"], :name => "complete8"
  add_index "complete", ["a9", "hostname"], :name => "complete9"

  create_table "conference_invitees", :force => true do |t|
    t.integer  "conference_id"
    t.integer  "phone_book_entry_id"
    t.string   "pin"
    t.boolean  "speaker"
    t.boolean  "moderator"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "uuid"
  end

  create_table "conferences", :force => true do |t|
    t.string   "name"
    t.datetime "start"
    t.datetime "end"
    t.text     "description"
    t.string   "pin"
    t.text     "state"
    t.boolean  "open_for_anybody"
    t.string   "conferenceable_type"
    t.integer  "conferenceable_id"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.integer  "max_members"
    t.boolean  "announce_new_member_by_name"
    t.boolean  "announce_left_member_by_name"
    t.string   "uuid"
  end

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.string   "country_code"
    t.string   "international_call_prefix"
    t.string   "trunk_prefix"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.string   "queue"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "fax_accounts", :force => true do |t|
    t.string   "fax_accountable_type"
    t.integer  "fax_accountable_id"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "tenant_id"
    t.string   "station_id"
    t.integer  "days_till_auto_delete"
    t.integer  "retries"
    t.string   "uuid"
  end

  create_table "fax_documents", :force => true do |t|
    t.boolean  "inbound"
    t.string   "state"
    t.integer  "transmission_time"
    t.datetime "sent_at"
    t.integer  "document_total_pages"
    t.integer  "document_transferred_pages"
    t.boolean  "ecm_requested"
    t.boolean  "ecm_used"
    t.string   "image_resolution"
    t.string   "image_size"
    t.string   "local_station_id"
    t.integer  "result_code"
    t.string   "remote_station_id"
    t.boolean  "success"
    t.integer  "transfer_rate"
    t.string   "document"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "fax_account_id"
    t.string   "caller_id_number"
    t.string   "caller_id_name"
    t.integer  "retry_counter"
    t.string   "tiff"
    t.integer  "fax_resolution_id"
    t.string   "uuid"
  end

  create_table "fax_pages", :force => true do |t|
    t.integer  "position"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "fax_page"
  end

  create_table "fax_resolutions", :force => true do |t|
    t.string   "name"
    t.string   "resolution_value"
    t.integer  "position"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  create_table "fax_thumbnails", :force => true do |t|
    t.integer  "fax_document_id"
    t.integer  "position"
    t.string   "thumbnail"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "faxes", :force => true do |t|
    t.boolean  "inbound"
    t.integer  "faxable_id"
    t.string   "faxable_type"
    t.string   "state"
    t.integer  "transmission_time"
    t.datetime "sent_at"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "document_total_pages"
    t.integer  "document_transferred_pages"
    t.boolean  "ecm_requested"
    t.boolean  "ecm_used"
    t.string   "image_resolution"
    t.string   "image_size"
    t.string   "local_station_id"
    t.integer  "result_code"
    t.string   "result_text"
    t.string   "remote_station_id"
    t.boolean  "success"
    t.integer  "transfer_rate"
    t.string   "t38_gateway_format"
    t.string   "t38_peer"
    t.string   "fax"
  end

  create_table "fifo_bridge", :id => false, :force => true do |t|
    t.string  "fifo_name",               :limit => 1024, :null => false
    t.string  "caller_uuid",                             :null => false
    t.string  "caller_caller_id_name",                   :null => false
    t.string  "caller_caller_id_number",                 :null => false
    t.string  "consumer_uuid",                           :null => false
    t.string  "consumer_outgoing_uuid"
    t.integer "bridge_start"
  end

  create_table "fifo_callers", :id => false, :force => true do |t|
    t.string  "fifo_name",               :null => false
    t.string  "uuid",                    :null => false
    t.string  "caller_caller_id_name"
    t.string  "caller_caller_id_number"
    t.integer "timestamp"
  end

  create_table "fifo_outbound", :id => false, :force => true do |t|
    t.string  "uuid"
    t.string  "fifo_name"
    t.string  "originate_string"
    t.integer "simo_count"
    t.integer "use_count"
    t.integer "timeout"
    t.integer "lag"
    t.integer "next_avail",                   :default => 0, :null => false
    t.integer "expires",                      :default => 0, :null => false
    t.integer "static",                       :default => 0, :null => false
    t.integer "outbound_call_count",          :default => 0, :null => false
    t.integer "outbound_fail_count",          :default => 0, :null => false
    t.string  "hostname"
    t.integer "taking_calls",                 :default => 1, :null => false
    t.string  "status"
    t.integer "outbound_call_total_count",    :default => 0, :null => false
    t.integer "outbound_fail_total_count",    :default => 0, :null => false
    t.integer "active_time",                  :default => 0, :null => false
    t.integer "inactive_time",                :default => 0, :null => false
    t.integer "manual_calls_out_count",       :default => 0, :null => false
    t.integer "manual_calls_in_count",        :default => 0, :null => false
    t.integer "manual_calls_out_total_count", :default => 0, :null => false
    t.integer "manual_calls_in_total_count",  :default => 0, :null => false
    t.integer "ring_count",                   :default => 0, :null => false
    t.integer "start_time",                   :default => 0, :null => false
    t.integer "stop_time",                    :default => 0, :null => false
  end

  create_table "gateway_parameters", :force => true do |t|
    t.integer  "gateway_id"
    t.string   "name"
    t.string   "value"
    t.string   "class_type"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "gateway_settings", :force => true do |t|
    t.integer  "gateway_id"
    t.string   "name"
    t.string   "value"
    t.string   "class_type"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "gateways", :force => true do |t|
    t.string   "name"
    t.string   "technology"
    t.boolean  "inbound"
    t.boolean  "outbound"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "gemeinschaft_setups", :force => true do |t|
    t.integer  "user_id"
    t.integer  "sip_domain_id"
    t.integer  "country_id"
    t.integer  "language_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "default_area_code"
    t.string   "default_company_name"
    t.string   "default_system_email"
    t.string   "trunk_access_code"
  end

  create_table "gs_cluster_sync_log_entries", :force => true do |t|
    t.integer  "gs_node_id"
    t.string   "class_name"
    t.string   "action"
    t.text     "content"
    t.string   "status"
    t.string   "history"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "homebase_ip_address"
    t.boolean  "waiting_to_be_synced"
    t.string   "association_method"
    t.string   "association_uuid"
  end

  create_table "gs_nodes", :force => true do |t|
    t.string   "name"
    t.string   "ip_address"
    t.boolean  "push_updates_to"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "site"
    t.string   "element_name"
    t.boolean  "accepts_updates_from"
    t.datetime "last_sync"
  end

  create_table "gs_parameters", :force => true do |t|
    t.string   "name"
    t.string   "section"
    t.text     "value"
    t.string   "class_type"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "entity"
  end

  create_table "gui_function_memberships", :force => true do |t|
    t.integer  "gui_function_id"
    t.integer  "user_group_id"
    t.boolean  "activated"
    t.string   "output"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "gui_functions", :force => true do |t|
    t.string   "category"
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "hunt_group_members", :force => true do |t|
    t.integer  "hunt_group_id"
    t.string   "name"
    t.integer  "position"
    t.boolean  "active"
    t.boolean  "can_switch_status_itself"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "uuid"
  end

  add_index "hunt_group_members", ["uuid"], :name => "index_hunt_group_members_on_uuid"

  create_table "hunt_groups", :force => true do |t|
    t.integer  "tenant_id"
    t.string   "name"
    t.string   "strategy"
    t.integer  "seconds_between_jumps"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.integer  "gs_node_id"
    t.integer  "gs_node_original_id"
    t.string   "uuid"
  end

  add_index "hunt_groups", ["uuid"], :name => "index_hunt_groups_on_uuid"

  create_table "interfaces", :id => false, :force => true do |t|
    t.string "type",        :limit => 128
    t.string "name",        :limit => 1024
    t.string "description", :limit => 4096
    t.string "ikey",        :limit => 1024
    t.string "filename",    :limit => 4096
    t.string "syntax",      :limit => 4096
    t.string "hostname",    :limit => 256
  end

  create_table "intruders", :force => true do |t|
    t.string   "list_type"
    t.string   "key"
    t.integer  "points"
    t.integer  "bans"
    t.datetime "ban_last"
    t.datetime "ban_end"
    t.string   "contact_ip"
    t.integer  "contact_port"
    t.integer  "contact_count"
    t.datetime "contact_last"
    t.float    "contacts_per_second"
    t.float    "contacts_per_second_max"
    t.string   "user_agent"
    t.string   "to_user"
    t.string   "comment"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "intruders", ["key"], :name => "index_intruders_on_key", :unique => true

  create_table "languages", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "manufacturers", :force => true do |t|
    t.string   "name"
    t.string   "ieee_name"
    t.string   "homepage_url"
    t.string   "state"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "nat", :id => false, :force => true do |t|
    t.integer "sticky"
    t.integer "port"
    t.integer "proto"
    t.string  "hostname", :limit => 256
  end

  add_index "nat", ["port", "proto", "hostname"], :name => "nat_map_port_proto"

  create_table "ouis", :force => true do |t|
    t.integer  "manufacturer_id"
    t.string   "value"
    t.string   "state"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "phone_book_entries", :force => true do |t|
    t.integer  "phone_book_id"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.string   "title"
    t.string   "nickname"
    t.string   "organization"
    t.boolean  "is_organization"
    t.string   "department"
    t.string   "job_title"
    t.boolean  "is_male"
    t.date     "birthday"
    t.string   "birth_name"
    t.string   "state"
    t.text     "description"
    t.integer  "position"
    t.string   "homepage_personal"
    t.string   "homepage_organization"
    t.string   "twitter_account"
    t.string   "facebook_account"
    t.string   "google_plus_account"
    t.string   "xing_account"
    t.string   "linkedin_account"
    t.string   "mobileme_account"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
    t.string   "image"
    t.string   "first_name_phonetic"
    t.string   "last_name_phonetic"
    t.string   "organization_phonetic"
    t.string   "value_of_to_s"
    t.string   "uuid"
  end

  add_index "phone_book_entries", ["first_name"], :name => "index_phone_book_entries_on_first_name"
  add_index "phone_book_entries", ["first_name_phonetic"], :name => "index_phone_book_entries_on_first_name_phonetic"
  add_index "phone_book_entries", ["last_name"], :name => "index_phone_book_entries_on_last_name"
  add_index "phone_book_entries", ["last_name_phonetic"], :name => "index_phone_book_entries_on_last_name_phonetic"
  add_index "phone_book_entries", ["organization"], :name => "index_phone_book_entries_on_organization"
  add_index "phone_book_entries", ["organization_phonetic"], :name => "index_phone_book_entries_on_organization_phonetic"
  add_index "phone_book_entries", ["uuid"], :name => "index_phone_book_entries_on_uuid"

  create_table "phone_books", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "phone_bookable_id"
    t.string   "phone_bookable_type"
    t.string   "state"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "uuid"
  end

  create_table "phone_models", :force => true do |t|
    t.string   "name"
    t.string   "manufacturer_id"
    t.string   "product_manual_homepage_url"
    t.string   "product_homepage_url"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "state"
    t.string   "uuid"
  end

  create_table "phone_number_ranges", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "phone_number_rangeable_type"
    t.integer  "phone_number_rangeable_id"
    t.string   "uuid"
  end

  add_index "phone_number_ranges", ["uuid"], :name => "index_phone_number_ranges_on_uuid"

  create_table "phone_numbers", :force => true do |t|
    t.string   "name"
    t.string   "number"
    t.string   "country_code"
    t.string   "area_code"
    t.string   "subscriber_number"
    t.string   "extension"
    t.integer  "position"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "central_office_code"
    t.string   "phone_numberable_type"
    t.integer  "phone_numberable_id"
    t.string   "state"
    t.string   "value_of_to_s"
    t.integer  "gs_node_id"
    t.integer  "gs_node_original_id"
    t.string   "uuid"
    t.integer  "access_authorization_user_id"
    t.boolean  "is_native"
  end

  add_index "phone_numbers", ["uuid"], :name => "index_phone_numbers_on_uuid"

  create_table "phone_sip_accounts", :force => true do |t|
    t.integer  "phone_id"
    t.integer  "sip_account_id"
    t.integer  "position"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "phones", :force => true do |t|
    t.string   "mac_address"
    t.integer  "phone_model_id"
    t.string   "ip_address"
    t.string   "last_ip_address"
    t.string   "http_user"
    t.string   "http_password"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.string   "state"
    t.string   "phoneable_type"
    t.integer  "phoneable_id"
    t.boolean  "hot_deskable"
    t.boolean  "nightly_reboot"
    t.string   "provisioning_key"
    t.boolean  "provisioning_key_active"
    t.integer  "tenant_id"
    t.integer  "fallback_sip_account_id"
  end

  create_table "registrations", :id => false, :force => true do |t|
    t.string  "reg_user"
    t.string  "realm",         :limit => 256
    t.string  "token",         :limit => 256
    t.text    "url"
    t.integer "expires"
    t.string  "network_ip",    :limit => 256
    t.string  "network_port",  :limit => 256
    t.string  "network_proto", :limit => 256
    t.string  "hostname",      :limit => 256
  end

  add_index "registrations", ["reg_user", "realm", "hostname"], :name => "regindex1"

  create_table "ringtones", :force => true do |t|
    t.string   "ringtoneable_type"
    t.integer  "ringtoneable_id"
    t.string   "audio"
    t.integer  "bellcore_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "route_elements", :force => true do |t|
    t.integer  "call_route_id"
    t.string   "var_in"
    t.string   "var_out"
    t.string   "pattern"
    t.string   "replacement"
    t.string   "action"
    t.boolean  "mandatory"
    t.integer  "position"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "sip_accounts", :force => true do |t|
    t.string   "sip_accountable_type"
    t.integer  "sip_accountable_id"
    t.string   "auth_name"
    t.string   "caller_name"
    t.string   "password"
    t.string   "voicemail_pin"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "value_of_to_s"
    t.integer  "tenant_id"
    t.integer  "sip_domain_id"
    t.boolean  "call_waiting"
    t.boolean  "clir"
    t.string   "clip_no_screening"
    t.boolean  "clip"
    t.string   "description"
    t.boolean  "callforward_rules_act_per_sip_account"
    t.boolean  "hotdeskable"
    t.integer  "gs_node_id"
    t.integer  "gs_node_original_id"
    t.string   "uuid"
    t.boolean  "is_native"
  end

  add_index "sip_accounts", ["uuid"], :name => "index_sip_accounts_on_uuid"

  create_table "sip_domains", :force => true do |t|
    t.string   "host"
    t.string   "realm"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sip_registrations", :id => false, :force => true do |t|
    t.string  "call_id"
    t.string  "sip_user"
    t.string  "sip_host"
    t.string  "presence_hosts"
    t.string  "contact",          :limit => 1024
    t.string  "status"
    t.string  "rpid"
    t.integer "expires"
    t.string  "user_agent"
    t.string  "server_user"
    t.string  "server_host"
    t.string  "profile_name"
    t.string  "hostname"
    t.string  "network_ip"
    t.string  "network_port",     :limit => 6
    t.string  "sip_username"
    t.string  "sip_realm"
    t.string  "mwi_user"
    t.string  "mwi_host"
    t.string  "orig_server_host"
    t.string  "orig_hostname"
    t.string  "sub_host"
  end

  add_index "sip_registrations", ["call_id"], :name => "sr_call_id"
  add_index "sip_registrations", ["contact"], :name => "sr_contact"
  add_index "sip_registrations", ["expires"], :name => "sr_expires"
  add_index "sip_registrations", ["hostname"], :name => "sr_hostname"
  add_index "sip_registrations", ["mwi_host"], :name => "sr_mwi_host"
  add_index "sip_registrations", ["mwi_user"], :name => "sr_mwi_user"
  add_index "sip_registrations", ["network_ip"], :name => "sr_network_ip"
  add_index "sip_registrations", ["network_port"], :name => "sr_network_port"
  add_index "sip_registrations", ["orig_hostname"], :name => "sr_orig_hostname"
  add_index "sip_registrations", ["orig_server_host"], :name => "sr_orig_server_host"
  add_index "sip_registrations", ["presence_hosts"], :name => "sr_presence_hosts"
  add_index "sip_registrations", ["profile_name"], :name => "sr_profile_name"
  add_index "sip_registrations", ["sip_host"], :name => "sr_sip_host"
  add_index "sip_registrations", ["sip_realm"], :name => "sr_sip_realm"
  add_index "sip_registrations", ["sip_user"], :name => "sr_sip_user"
  add_index "sip_registrations", ["sip_username"], :name => "sr_sip_username"
  add_index "sip_registrations", ["status"], :name => "sr_status"
  add_index "sip_registrations", ["sub_host"], :name => "sr_sub_host"

  create_table "softkey_functions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "position"
  end

  add_index "softkey_functions", ["name"], :name => "index_softkey_functions_on_name"
  add_index "softkey_functions", ["position"], :name => "index_softkey_functions_on_position"

  create_table "softkeys", :force => true do |t|
    t.string   "function"
    t.string   "number"
    t.string   "label"
    t.integer  "position"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "sip_account_id"
    t.integer  "softkey_function_id"
    t.string   "uuid"
    t.string   "softkeyable_type"
    t.integer  "softkeyable_id"
  end

  create_table "tasks", :id => false, :force => true do |t|
    t.integer "task_id"
    t.string  "task_desc",        :limit => 4096
    t.string  "task_group",       :limit => 1024
    t.integer "task_sql_manager"
    t.string  "hostname",         :limit => 256
  end

  add_index "tasks", ["hostname", "task_id"], :name => "tasks1", :unique => true

  create_table "tenant_memberships", :force => true do |t|
    t.integer  "tenant_id"
    t.integer  "user_id"
    t.string   "state"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "tenants", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "state"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.integer  "country_id"
    t.integer  "sip_domain_id"
    t.integer  "language_id"
    t.string   "internal_extension_ranges"
    t.string   "did_list"
    t.string   "from_field_voicemail_email"
    t.string   "from_field_pin_change_email"
    t.string   "uuid"
  end

  create_table "user_group_memberships", :force => true do |t|
    t.integer  "user_group_id"
    t.integer  "user_id"
    t.string   "state"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "user_groups", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "tenant_id"
    t.integer  "position"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "user_name"
    t.string   "email"
    t.string   "password_digest"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.boolean  "male"
    t.string   "gemeinschaft_unique_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.string   "image"
    t.integer  "current_tenant_id"
    t.string   "pin_salt"
    t.string   "pin_hash"
    t.integer  "language_id"
    t.boolean  "send_voicemail_as_email_attachment"
    t.string   "importer_checksum"
    t.integer  "gs_node_id"
    t.integer  "gs_node_original_id"
    t.string   "uuid"
    t.boolean  "is_native"
  end

  add_index "users", ["uuid"], :name => "index_users_on_uuid"

  create_table "voicemail_msgs", :id => false, :force => true do |t|
    t.integer "created_epoch"
    t.integer "read_epoch"
    t.string  "username"
    t.string  "domain"
    t.string  "uuid"
    t.string  "cid_name"
    t.string  "cid_number"
    t.string  "in_folder"
    t.string  "file_path"
    t.integer "message_len"
    t.string  "flags"
    t.string  "read_flags"
    t.string  "forwarded_by"
    t.boolean "notification"
  end

  add_index "voicemail_msgs", ["created_epoch"], :name => "voicemail_msgs_idx1"
  add_index "voicemail_msgs", ["domain"], :name => "voicemail_msgs_idx3"
  add_index "voicemail_msgs", ["forwarded_by"], :name => "voicemail_msgs_idx7"
  add_index "voicemail_msgs", ["in_folder"], :name => "voicemail_msgs_idx5"
  add_index "voicemail_msgs", ["read_flags"], :name => "voicemail_msgs_idx6"
  add_index "voicemail_msgs", ["username"], :name => "voicemail_msgs_idx2"
  add_index "voicemail_msgs", ["uuid"], :name => "voicemail_msgs_idx4"

  create_table "voicemail_prefs", :id => false, :force => true do |t|
    t.string  "username"
    t.string  "domain"
    t.string  "name_path"
    t.string  "greeting_path"
    t.string  "password"
    t.boolean "notify"
    t.boolean "attachment"
    t.boolean "mark_read"
    t.boolean "purge"
  end

  add_index "voicemail_prefs", ["domain"], :name => "voicemail_prefs_idx2"
  add_index "voicemail_prefs", ["username"], :name => "voicemail_prefs_idx1"

  create_table "whitelists", :force => true do |t|
    t.string   "name"
    t.string   "whitelistable_type"
    t.integer  "whitelistable_id"
    t.integer  "position"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
    t.string   "uuid"
  end

end
