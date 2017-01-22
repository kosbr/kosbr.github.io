---
layout: post
title:  "Qooxdoo autocomplete combobox"
date:   2017-01-22 14:30:39 +0600
categories:
tags: Qooxdoo
---

By this moment I have been developing and fixing bugs of the [qooxdoo][qooxdoo]{:target="_blank"}  application for several months. It is rather old
 framework, but nowadays it still alive, however it is not so popular. Actually it has never been very popular, it is seen
 when you start google something - the most often result is official documentation and nothing else. It should be noted,
 the framework documentation is rather good. The qooxdoo has a lot of different widgets and it seems that all your
 need is already implemented there or it is needed make a tiny modification of existing item to get what you want. I was
  wonder when I realized that there is no autocomplete combobox widget. Moreover, there is almost nothing about it in the
  internet. So I had to do it myself.

 ![autocomplete](/images/articles/qooxdoo_autocomplete/autocomplete.gif)

 Actually it is easy to do such widget for personal usage,  it can be a task for beginners. The most complex part is
 to make it good for all, make it ready to push into framework repository. In such case it must be well tested and has a lot
 of options for customizations. Unfortunately, I don't have time for it, so I've just done it for myself. However, I'd like
 to publish it, maybe next person who faces with such problem will solve it easier. Actually I've found in the internet one
 not finished implementation of this widget and made my one based on it.

 The code is below:

 {% highlight javascript %}
 qx.Class.define("project.widgets.AutoCompleteComboBox",
     {
         extend: qx.ui.form.ComboBox,

         properties: {

             model: {
                 init: null,
                 nullable: true,
                 check: "qx.type.Array",
                 apply: "_applyModel"
             },
             displayPropertyName: {
                 init: null,
                 nullable: true,
                 check: "String",
                 event: "changeDisplayPropertyName",
                 apply: "_applyDisplayPropertyName"
             },

             showAllIfTextIsEmpty: {
                 init: true,
                 check: "Boolean"
             }
         },

         members: {
             __listItems : null,

             getSelectedItem: function(){
                 var list = this.getChildControl("list");
                 var selection = list.getSelection();
                 if (selection && selection.length > 0) {
                     var model  = selection[0].getModel();
                     return model;
                 }
                 return null;
             },

             resetSelection: function() {
                 var list = this.getChildControl("list");
                 list.setSelection([]);
                 this.setValue("");
             },

             _keyHandler: function(e) {
                 var key = e.getKeyIdentifier();

                 if (key == "Escape") {
                     this.close();
                     return;
                 }

                 if (key == "Enter") {
                     // fill by selected value
                     if (this.__preSelectedItem) {
                         var list = this.getChildControl("list");
                         list.setSelection([this.__preSelectedItem]);
                     }
                     this.close();
                     return;
                 }

                 if (key == "Left" || key == "Right" || key == "Home" || key == "End" || key == "Backspace") {
                     // moving cursor, autocomplete is not needed
                     e.stopPropagation();
                 }

                 if(key == "Down" || key == "Up" || key == "Tab") {
                     // user is selecting an item.
                     // Fix 'hovered' bug.
                     if (this.__listItems != null) {
                         for(i = 0; i <= this.__listItems.length; i++) {
                             var currentListItem = this.__listItems[i];
                             if(!currentListItem) {
                                 continue;
                             }
                             currentListItem.removeState("hovered");
                         }
                     }
                     // autocomplete is not needed because text is the same
                     this.open();
                     return;
                 }

                 //autocomplete part. Remove all items and add only proper ones.
                 this._updateDropDownItems();
                 var availableItemsNumber = this.getChildren().length;
                 if (availableItemsNumber == 0) {
                     // todo translation
                     var notFoundListItem = new qx.ui.form.ListItem("No results found");
                     notFoundListItem.setEnabled(false);
                     this.add(notFoundListItem);
                 }
                 this.open();
             },

             _updateDropDownItems: function () {
                 this.removeAll();
                 var enteredText = this.getValue();
                 var forceAddAll = this.getShowAllIfTextIsEmpty() && !enteredText;

                 if (this.__listItems) {
                     for (var i = 0; i <= this.__listItems.length; i++) {
                         var currentListItem = this.__listItems[i];
                         if (!currentListItem || !currentListItem.getLabel()) {
                             continue;
                         }



                         if (forceAddAll || currentListItem.getLabel().toUpperCase()
                                 .match(new RegExp(enteredText.toUpperCase(), ""), "")) {
                             this.add(currentListItem);
                         }
                     }
                 }
             },

             _applyModel: function (newModel) {
                 this._clearBindings();
                 this.__listItems = [];
                 if (newModel) {
                     newModel.forEach(function (modelItem) {
                         if (modelItem) {
                             var listItem = new qx.ui.form.ListItem(null, null, modelItem);
                             modelItem.bind(this.getDisplayPropertyName(), listItem, "label");
                             this.__listItems.push(listItem);
                         }
                     }, this);
                 }

                 this._updateDropDownItems();
             },

             _clearBindings: function () {
                 if (this.__listItems) {
                     this.__listItems.forEach(function (listItem) {
                         qx.data.SingleValueBinding.removeAllBindingsForObject(listItem);
                     });
                 }
             },

             _applyDisplayPropertyName: function (newDisplayProperty) {
                 this._applyModel(this.getModel());
             }
         },

         construct : function() {
             this.base(arguments);

             var textfield = this.getChildControl("textfield");

             textfield.addListener("keydown",this._keyHandler,this);
             textfield.addListener("keypress",this._keyHandler,this);
             textfield.addListener("keyup",this._keyHandler,this);


             //if clicked, the combobox will extend with all the items
             textfield.addListener("mouseup",function(e){
                 var context = this;
                 this._updateDropDownItems();
                 setTimeout(
                     function(){
                         context.open();
                     },300
                 );
             },this);
         }

     });
 {% endhighlight %}


 [qooxdoo]:  http://www.qooxdoo.org/