'use strict';

let net = require('net');

let HOST = "127.0.0.1";
let PORT = 2333;
var local;

module.exports = local = {
	register: function(username, password, email, nickname, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
		})
		let request = {"module": "ha_user", "function": "register", "arg": [username, password, email, nickname]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	} 
}