'use strict';

let net = require('net');

let HOST = "127.0.0.1";
let PORT = 2333;
var local;

module.exports = local = {
	renderIndex: function(index, offset, callback) {
		let client = new net.Socket().connect(PORT, HOST);
		client.on('data', (data) => {
			let reply = "" + data;
			callback(reply);
			client.end();
		})
		let request = {"module": "index", "function": "render_index", "arg": [index, offset]};
		let buf = new Buffer(JSON.stringify(request));
		client.write(buf);
	}
}