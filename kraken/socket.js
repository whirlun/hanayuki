var net = require('net');

var server = net.createServer();

server.on('connection', (client) =>
		client.on('data', (data) =>
			broadcast(data, client);)
		);

function broadcast(message, client) {
	
}