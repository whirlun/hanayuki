'use strict';

let net = require('net');

let HOST = "127.0.0.1";
let PORT = 2333;
var local;

module.exports = local = {
	read: function(threadid ,username, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
	})
	let request = {"module": "ha_thread", "function": "read_thread", "arg": [threadid, username]};
	let buf = new Buffer(JSON.stringify(request));
	client.write(buf);
	},

	reply: function(threadid, content, username, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end()
		})
		let request = {"module": "ha_thread", "function": "reply_thread", "arg":[threadid, content, username]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	},

	getreply: function(threadid, replylist, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
	})
		console.log(replylist);
		let request = {"module": "ha_thread", "function": "get_reply", "arg":[threadid, replylist]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	}
}