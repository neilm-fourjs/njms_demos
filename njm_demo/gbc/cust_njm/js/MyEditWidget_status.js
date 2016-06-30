/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2016. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('MyEditWidget_status', ['EditWidget', 'WidgetFactory'],
    /**
     * @param {gbc} context
     * @param {classes} cls
     */
    function(context, cls) {

      /**
       * Edit widget always displaying its tooltip
       * @class classes.MyEditWidget
       * @extends classes.EditWidget
       */
      cls.MyEditWidget_status = context.oo.Class(cls.EditWidget, function($super) {
        /** @lends classes.MyEditWidget_status.prototype */
        return {
          __name: "MyEditWidget_status",
          __dataContentPlaceholderSelector: '.gbc_dataContentPlaceholder',

          setTitle: function(title) {
            $(this.getElement()).find(".title").text(title);
						/** NJM */
						//this._applicationHostWidget.getMenu().setText("Hello World");
          },

          getTitle: function() {
            return $(this.getElement()).find(".title").text();
          }
        };
      });

      cls.WidgetFactory.register('Edit', 'gbc_status', cls.MyEditWidget_status);
    });
