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

modulum('MyEditWidget', ['EditWidget', 'WidgetFactory'],
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
      cls.MyEditWidget = context.oo.Class(cls.EditWidget, function($super) {
        /** @lends classes.MyEditWidget.prototype */
        return {
          __name: "MyEditWidget",
          __dataContentPlaceholderSelector: '.gbc_dataContentPlaceholder',

          setTitle: function(title) {
            $(this.getElement()).find(".title").text(title);
          },

          getTitle: function() {
            return $(this.getElement()).find(".title").text();
          }
        };
      });

      /*
       *  This is a sample widget that would replace the default one in GWC-JS
       *  To activate it, please uncomment the line below. This will override
       *  the original widget registration to this one.
       */

      // cls.WidgetFactory.register('Edit', cls.MyEditWidget);
    });
