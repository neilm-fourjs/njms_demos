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

modulum('MyLabelWidget_stat', ['TextWidgetBase', 'WidgetFactory'],
  /**
   * @param {gbc} context
   * @param {classes} cls
   */
  function(context, cls) {

    /**
     * Label widget.
     * @class classes.MyLabelWidget_stat
     * @extends classes.TextWidgetBase
     */
    cls.MyLabelWidget_stat = context.oo.Class(cls.TextWidgetBase, function($super) {
      /** @lends classes.MyLabelWidget_stat.prototype */
      return {
        __name: "MyLabelWidget_stat",
        __dataContentPlaceholderSelector: cls.WidgetBase.selfDataContent,
        /**
         * @type {Element}
         */
        _textContainer: null,
        _hasHTMLContent: false,
        _value: null,
        _displayFormat: null,

        _initLayout: function() {
          $super._initLayout.call(this);
          this._layoutEngine = new cls.LeafLayoutEngine(this);
          this._layoutInformation.forcedMinimalWidth = 16;
          this._layoutInformation.forcedMinimalHeight = 16;
        },

        _initElement: function() {
          $super._initElement.call(this);
          this._textContainer = this._element.getElementsByTagName('span')[0];
          this._element.on('click.MyLabelWidget_stat', this._onClick.bind(this));
        },

        destroy: function() {
          this._element.off('click.MyLabelWidget_stat');
          $super.destroy.call(this);
        },

        _onClick: function(event) {
          this.emit(context.constants.widgetEvents.focus, event);
          this.emit(context.constants.widgetEvents.click, event);
        },

        getDisplayFormat: function() {
          return this._displayFormat;
        },

        /**
         * Set current display format to use on each set value
         * @param format
         */
        setDisplayFormat: function(format) {
          this._displayFormat = format;
        },

        /**
         * @param {string} value sets the value to display
         */
        setValue: function(value) {
          var formattedValue = value; //this.getFormattedValue(value, this._displayFormat);
          this.getLayoutInformation().invalidateInitialMeasure(!this._value && !!formattedValue);
          this._value = formattedValue;
          if (this._hasHTMLContent === true) {
            this._textContainer.innerHTML = formattedValue;
          } else {
            if (!!formattedValue || formattedValue === 0 || formattedValue === false) {
              this._textContainer.textContent = formattedValue;
            } else {
              this._textContainer.textContent = '\u00a0';
            }
          }
          this.getLayoutInformation().invalidateMeasure();
					context.HostService.getApplicationHostWidget().getMenu().setText( formattedValue );
        },

        /**
         * @returns {string} the displayed value
         */
        getValue: function() {
          if (this._hasHTMLContent === true) {
            return this._textContainer.innerHTML;
          } else {
            var content = this._textContainer.textContent;
            if (content === '\u00a0') {
              return "";
            }
            return content;
          }
        },

        setFocus: function() {
          this._element.domFocus();
        },

        setHtmlControl: function(jcontrol) {
          var value = this.getValue();
          jcontrol.innerHTML = value;
          jcontrol.addClass("gwcjs-label-text-container");
          this._textContainer.replaceWith(jcontrol);
          this._textContainer = jcontrol;
        }
      };
    });
    cls.WidgetFactory.register('Label', 'gbc_status', cls.MyLabelWidget_stat);
  });
