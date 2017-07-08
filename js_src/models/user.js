'use strict';

let net = require('net');

let HOST = "127.0.0.1";
let PORT = 2333;
var local;

module.exports = local = {
	register: function(username, password, nickname, email, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
		})
		let request = {"module": "ha_user", "function": "register", "arg": [username, password, nickname, email]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	},

	login: function(username, password, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
		})
		let request = {"module": "ha_user", "function": "login", "arg": [username, password]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	},
	userpage: function(username, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
		})
		let request = {"module": "ha_user", "function":"userpage", "arg": [username]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	},
	activities: function(threads,username, page, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) =>
		{
			let reply = "" + data;
			callback(reply);
			client.end();
		})
		let request = {"module": "ha_user", "function": "activities", "arg": [username, page]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	}
}
