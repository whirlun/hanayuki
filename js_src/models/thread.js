'use strict';

let net = require('net');

let HOST = "127.0.0.1";
let PORT = 2333;
var local;

module.exports = local = {
	read: function(threadid, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
	})
	let request = {"module": "ha_thread", "function": "read_thread", "arg": [threadid]};
	let buf = new Buffer(JSON.stringify(request));
	client.write(buf);
}
}