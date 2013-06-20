App = Ember.Application.create({
  LOG_TRANSITIONS: true,
  rootElement: '#emberjs-container',

  // Reload the switchboard every x milliseconds
  // if reload_interval != 0
  ready: function() {
    if (reload_interval != 0) {
      var switchboard = App.Switchboard.find(switchboard_id);
      setInterval(function() {
        switchboard.reload();

        // var switchboard_entries = App.SwitchboardEntry.find();
        // switchboard_entries.forEach(function(switchboard_entry) {
        //   switchboard_entry.reload();
        // });
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
  blind_transfer: function() {
    console.log('transfer')
  }
});

// Models
App.Store = DS.Store.extend();

DS.RESTAdapter.configure("plurals", {
  switchboard_entry: "switchboard_entries"
});

DS.RESTAdapter.reopen({
  namespace: 'api/v1'
});

App.Switchboard = DS.Model.extend({
  switchboardEntrys: DS.hasMany('App.SwitchboardEntry'),
  activeCalls: DS.hasMany('App.ActiveCall'),
  name: DS.attr('string')


});

App.SwitchboardEntry = DS.Model.extend({
  switchboard: DS.belongsTo('App.Switchboard'),
  sipAccount: DS.belongsTo('App.SipAccount'),
  name: DS.attr('string'),
  path_to_user: DS.attr('string'),
  avatar_src: DS.attr('string'),
  callstate: DS.attr('string')  
});

App.ActiveCall = DS.Model.extend({
  start_stamp: DS.attr('number'),
  callstate: DS.attr('string'),
  b_callstate: DS.attr('string'),
  destination: DS.attr('string'),
  b_caller_id_number: DS.attr('string')
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

  phoneNumberShortList: Ember.computed(function() {
      var phoneNumbers = this.get('phoneNumbers');
      return phoneNumbers.slice(0,amount_of_displayed_phone_numbers);
  }).property('phoneNumbers.@each.number')

});

App.PhoneNumber = DS.Model.extend({
  name: DS.attr('string'),
  number: DS.attr('string'),
  destination: DS.attr('string')
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
  }.property('b_callstate')  

});

App.store.adapter.serializer.configure(App.PhoneNumber, { sideloadAs: 'phone_numbers' });

Ember.Handlebars.registerBoundHelper('avatar_img', function(value) {
  return new Handlebars.SafeString('<img alt="Avatar image" class="img-rounded" src="' + value + '" style="width: 100px;">');
});

Ember.Handlebars.registerBoundHelper('show_callstate', function(value) {
  return new Handlebars.SafeString('<span class="label">' + value + '</span>');
});
