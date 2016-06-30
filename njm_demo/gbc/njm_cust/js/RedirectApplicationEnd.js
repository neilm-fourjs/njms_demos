"use strict";

// Add a dependence on ApplicationHostMenuWidget
modulum('RedirectApplicationEnd', ['ApplicationHostMenuWidget', 'WidgetFactory'],
  function(context, cls) {

    // Inherit from ApplicationHostMenuWidget class
    cls.RedirectApplicationEnd = context.oo.Class(cls.ApplicationHostMenuWidget, function($super) {
      return {
        __name: "RedirectApplicationEnd",
        // use the default template otherwise the framework search for RedirectApplicationEnd.tpl.html
        __templateName: "ApplicationHostMenuWidget",
        // member for ModelHelper object
        _model: null,
        // application counter
        _appsCount: null,

        /* your custom code */
        constructor: function() {
          $super.constructor.call(this);
          this._appsCount = 0;
          this._model = new cls.ModelHelper(this);
          this._model.addNewApplicationListener(this.onNewApplication.bind(this));
          this._model.addCloseApplicationListener(this.onCloseApplication.bind(this));
        },

        onNewApplication: function(application) {
          ++this._appsCount;
        },

        onCloseApplication: function(application) {
          --this._appsCount;
          if (this._appsCount == 0) {
            document.location.replace("/gbc/njm_demo.html");
          }
        }
      }
    });
    cls.WidgetFactory.register('ApplicationHostMenu', cls.RedirectApplicationEnd);
  });
