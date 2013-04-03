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

// Models
App.Store = DS.Store.extend({
  revision: 12
});

DS.RESTAdapter.configure("plurals", {
  switchboard_entry: "switchboard_entries"
});

DS.RESTAdapter.reopen({
  namespace: 'api/v1'
});

App.Switchboard = DS.Model.extend({
  switchboardEntrys: DS.hasMany('App.SwitchboardEntry'),
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

App.Adapter = DS.RESTAdapter.extend();

App.store = App.Store.create({
  adapter: App.Adapter.create()
});

App.store.adapter.serializer.configure(App.SwitchboardEntry, { sideloadAs: 'switchboard_entries' });

App.SipAccount = DS.Model.extend({
  switchboardEntrys: DS.hasMany('App.SwitchboardEntry'),
  phoneNumbers: DS.hasMany('App.PhoneNumber'),
  callerName: DS.attr('string'),
  authName: DS.attr('string')
});

App.PhoneNumber = DS.Model.extend({
  name: DS.attr('string'),
  number: DS.attr('string')
});

App.store.adapter.serializer.configure(App.PhoneNumber, { sideloadAs: 'phone_numbers' });

Ember.Handlebars.registerBoundHelper('avatar_img', function(value) {
  return new Handlebars.SafeString('<img alt="Avatar image" class="img-rounded" src="' + value + '" style="width: 100px;">');
});

Ember.Handlebars.registerBoundHelper('show_callstate', function(value) {
  return new Handlebars.SafeString('<span class="label">' + value + '</span>');
});
