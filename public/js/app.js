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
  revision: 11
});

DS.RESTAdapter.configure("plurals", {
  switchboard_entry: "switchboard_entries"
});

App.Switchboard = DS.Model.extend({
  switchboardEntrys: DS.hasMany('App.SwitchboardEntry'),
  name: DS.attr('string'),
});

App.SwitchboardEntry = DS.Model.extend({
  switchboard: DS.belongsTo('App.Switchboard'),
  switchboard: DS.belongsTo('App.SipAccount'),
  name: DS.attr('string'),
});

App.SipAccount = DS.Model.extend({
  switchboardEntrys: DS.hasMany('App.SwitchboardEntry'),
  callerName: DS.attr('string'),
});