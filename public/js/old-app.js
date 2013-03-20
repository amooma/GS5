App = Ember.Application.create({
  LOG_TRANSITIONS: true
});

// App.Router.map(function() {
//   this.resource("switchboards", { path: "/switchboards" });
// });

// App.TablesRoute = Ember.Route.extend({
//   model: function() {
//     return ;
//   }
// })

// DS.RESTAdapter.configure("plurals", {
//   switchboard_entry: "switchboard_entries"
// });


App.Store = DS.Store.extend({
  adapter: 'DS.FixtureAdapter',
  revision: 11
});

App.Switchboard = DS.Model.extend({
  switchboard_entrys: DS.hasMany('App.SwitchboardEntry'),
  name: DS.attr('string')
});

App.SwitchboardEntry = DS.Model.extend({
  name: DS.attr('string')
});

App.Router.map(function() {
  this.resource('switchboard', { path: '/users/:user_id/switchboards/:switchboard_id' });
});

App.SwitchboardsRoute = Ember.Route.extend({
  model: function(params) {
    return App.Switchboard.find(params.switchboard_id);
  }
});

App.Switchboard.FIXTURES = [{
  id: 1,
  name: 'Erstes Ember Test Switchboard'
}, {
  id: 2,
  name: 'Zweites Switchboard'
}]


// var switchboard_view = Ember.View.create({
//   templateName: 'switchboard',
//   name: "test"
// });

// switchboard_view.appendTo('#xxxyyy');
