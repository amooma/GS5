App = Ember.Application.create({
  LOG_TRANSITIONS: true,
  rootElement: '#container'
});

// Router
App.Router.map(function() {
  this.resource('switchboards', function() {
    this.resource('switchboard', { path: ':switchboard_id' });
  });
});

App.ApplicationRoute = Ember.Route.extend({
  setupController: function(controller) {
    // `controller` is the instance of ApplicationController
    controller.set('title', "Hello world! Switchboard #" + switchboard_id);
  }
});

App.SwitchboardsRoute = Ember.Route.extend({
  model: function() {
    return App.Switchboard.find();
  }
});

App.IndexRoute = Ember.Route.extend({
  redirect: function() {
    this.transitionTo('switchboard', App.Switchboard.find(switchboard_id));
  }  
});

// Controller
App.ApplicationController = Ember.Controller.extend({
  appName: 'My First Example'
});

App.SwitchboardsController = Ember.ArrayController.extend({
  // switchboardEntrys: table.get('tab.tabItems')
})

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
  didLoad: function() {
    console.log('Switchboard model loaded')
  }
});



App.SwitchboardEntry = DS.Model.extend({
  switchboard: DS.belongsTo('App.Switchboard'),
  name: DS.attr('string'),
  didLoad: function() {
    console.log('SwitchboardEntry model loaded')
  }
});

// // Views
// App.SwitchboardView = Ember.View.extend({
//   templateName: 'switchboard'
// });