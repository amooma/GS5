App = Ember.Application.create({
  rootElement: '#emberjs-container',

  // Reload the switchboard every x milliseconds
  // if reload_interval != 0
  ready: function() {
    if (reload_interval != 0) {
      var switchboard = App.Switchboard.find(switchboard_id);
      setInterval(function() {
        switchboard.reload();
      }, reload_interval);
    }
  }
});

// Router
App.Router.map(function() {
  this.resource('switchboard', { path: '/' });
});

App.SwitchboardRoute = Ember.Route.extend({
  model: function() {
    return App.Switchboard.find(switchboard_id);
  }
});

// Controller
App.SwitchboardController = Ember.ObjectController.extend({
  transfer_blind: function(call_id, destination) {
    request_url = '/api/v1/calls/' + call_id + '.json';
    jQuery.get(request_url, { transfer_blind: destination });
  },

  transfer_attended: function(call_id, destination) {
    request_url = '/api/v1/calls/' + call_id + '.json';
    jQuery.get(request_url, { transfer_attended: destination });
  },

  searchText: null,

  searchResults: function() {
    var searchText = this.get('searchText');
    if (!searchText) { return; }
    return App.PhoneBookEntry.find({ query: searchText });
  }.property('searchText')
});

// Models
App.Store = DS.Store.extend();

DS.RESTAdapter.configure("plurals", {
  switchboard_entry: "switchboard_entries",
  phone_book_entry: "phone_book_entries"
});

DS.RESTAdapter.reopen({
  namespace: 'api/v1'
});

App.Switchboard = DS.Model.extend({
  switchboardEntrys: DS.hasMany('App.SwitchboardEntry'),
  activeCalls: DS.hasMany('App.ActiveCall'),
  dispatchableIncomingCalls: DS.hasMany('App.DispatchableIncomingCall'),
  name: DS.attr('string'),
  show_avatars: DS.attr('boolean'),
  blind_transfer_activated: DS.attr('boolean'),
  search_activated: DS.attr('boolean'),
  attended_transfer_activated: DS.attr('boolean')
});

App.SwitchboardEntry = DS.Model.extend({
  switchboard: DS.belongsTo('App.Switchboard'),
  sipAccount: DS.belongsTo('App.SipAccount'),
  name: DS.attr('string'),
  path_to_user: DS.attr('string'),
  avatar_src: DS.attr('string'),
  callstate: DS.attr('string'),
  switchable: DS.attr('boolean')
});

App.ActiveCall = DS.Model.extend({
  start_stamp: DS.attr('number'),
  callstate: DS.attr('string'),
  b_callstate: DS.attr('string'),
  destination: DS.attr('string'),
  b_caller_id_number: DS.attr('string'),

  isActive: function() {
    if (this.get('b_callstate') == 'ACTIVE') {
      return true
    } else {
      return false
    }
  }.property('b_callstate'),

  isRinging: function() {
    if (this.get('b_callstate') == 'RINGING') {
      return true
    } else {
      return false
    }
  }.property('b_callstate')  
});

App.DispatchableIncomingCall = DS.Model.extend({
  start_stamp: DS.attr('number'),
  callstate: DS.attr('string'),
  b_callstate: DS.attr('string'),
  destination: DS.attr('string'),
  b_caller_id_number: DS.attr('string'),

  isActive: function() {
    if (this.get('b_callstate') == 'ACTIVE') {
      return true
    } else {
      return false
    }
  }.property('b_callstate'),

  isRinging: function() {
    if (this.get('b_callstate') == 'RINGING') {
      return true
    } else {
      return false
    }
  }.property('b_callstate')  
});

App.Adapter = DS.RESTAdapter.extend();

App.store = App.Store.create({
  adapter: App.Adapter.create()
});

App.store.adapter.serializer.configure(App.SwitchboardEntry, { sideloadAs: 'switchboard_entries' });

App.SipAccount = DS.Model.extend({
  switchboardEntrys: DS.hasMany('App.SwitchboardEntry'),
  calls: DS.hasMany('App.Call'),
  phoneNumbers: DS.hasMany('App.PhoneNumber'),
  callerName: DS.attr('string'),
  authName: DS.attr('string'),
  is_registrated: DS.attr('boolean'),

  phoneNumberShortList: Ember.computed(function() {
      var phoneNumbers = this.get('phoneNumbers');
      return phoneNumbers.slice(0,amount_of_displayed_phone_numbers);
  }).property('phoneNumbers.@each.number')

});

App.Call = DS.Model.extend({
  start_stamp: DS.attr('number'),
  callstate: DS.attr('string'),
  b_callstate: DS.attr('string'),
  destination: DS.attr('string'),
  b_caller_id_number: DS.attr('string'),

  isActive: function() {
    if (this.get('b_callstate') == 'ACTIVE') {
      return true
    } else {
      return false
    }
  }.property('b_callstate'),

  isRinging: function() {
    if (this.get('b_callstate') == 'RINGING') {
      return true
    } else {
      return false
    }
  }.property('b_callstate')
});

App.PhoneBookEntry = DS.Model.extend({
  first_name: DS.attr('string'),
  last_name: DS.attr('string'),
  organization: DS.attr('string'),
  search_result_display: DS.attr('string'),
  phoneNumbers: DS.hasMany('App.PhoneNumber')
});

App.PhoneNumber = DS.Model.extend({
  name: DS.attr('string'),
  number: DS.attr('string'),
  destination: DS.attr('string')
});

App.store.adapter.serializer.configure(App.PhoneNumber, { sideloadAs: 'phone_numbers' });

// Handlebar Helpers
//
Ember.Handlebars.registerBoundHelper('avatar_img', function(value) {
  return new Handlebars.SafeString('<img alt="Avatar image" class="img-rounded" src="' + value + '" style="width: 100px;">');
});

Ember.Handlebars.registerBoundHelper('show_callstate', function(value) {
  if (value) {
    return new Handlebars.SafeString('<span class="label">' + value + '</span>');
  }
});

Ember.Handlebars.registerBoundHelper('from_now', function(start_stamp) {
  moment().lang('de');
  var day = moment.unix(start_stamp).fromNow();
  return day;
});

