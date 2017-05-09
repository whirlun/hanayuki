'use strict';

let rabbit = require('./rabbitConnection');
let model;
let events = require('events');
let ready = false;
let event = new events.EventEmitter();
exports.on = function on() {
    ready = true;
    console.log('ready to receive');
}

exports.IndexModel = function IndexModel() {
    rabbit.publish({target: 'index', index: 0, offset: 20});
    event.on('modelReady', () => {
            return model;
        })};

exports.callIndex = function callIndex(modeldata) {
    model = modeldata;
    console.log('receive model');
    event.emit('modelReady');
};
