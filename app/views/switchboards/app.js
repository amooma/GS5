window.App = Ember.Application.create({
    rootElement: '#xxxyyy',

    ready: function() { 
        App.view.appendTo('#xxxyyy');
    }
});

