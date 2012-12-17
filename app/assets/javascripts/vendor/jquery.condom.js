/* 
 * jQuery Condom (Use namespaces to protect your global integrity.) 
 * Version 0.0.3
 * 
 * Copyright (c) 2011 Mario "Kuroir" Ricalde (http://kuroir.com)  
 *   & Micha Niskin (micha@thinkminimo.com) 
 * Licensed jointly under the GPL and MIT licenses, 
 * choose which one suits your project best! 
 */ 
(function($) { 
  var methods = {}; 
  $.ns = function(ns) { 
    // Define namespace if it doesn't exist.
    methods[ns] =  methods[ns] || {}; 

    // Get reference to a namespaced jQ object
    function nsfun(selector, context) {
      return $(selector, context).ns(ns);
    }
    
    // Allows you to add methods ala jQuery.fn (useful to namespace premade plugins)
    nsfun.fn = methods[ns];

    // Add a method.
    nsfun.add = function(fname, fn) { 
      var new_funcs = typeof fname == "object" ? fname : {}; 
      // One method.
      if (new_funcs !== fname) 
        new_funcs[fname] = fn; 
      // Group of methods.
      $.each(new_funcs, function(fname, fn) { 
        methods[ns][fname] = function() { 
          fn.apply(this, arguments); 
          return this; 
        }; 
      }); 
      return this; 
    };

    // Get methods.
    nsfun.methods = function() { 
      return $.extend({}, methods[ns]); 
    };

    return nsfun;
  };
  // The only function that touches $.fn
  $.fn.ns = function(ns) { 
    if (methods[ns]) $.extend(this, methods[ns]); 
    return this; 
  }; 
})(jQuery);
