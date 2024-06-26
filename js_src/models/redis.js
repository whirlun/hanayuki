'use strict'
let redis = require('redis');
let net = require('net');

let HOST = "127.0.0.1";
let PORT = 2333;
let prefix = "ha_"
let local;

exports.getClient = () => {
  let client = redis.createClient(6379, '127.0.0.1', {"password":"1zHyBRMvAVA@s@%bu3Z"});
  global.redisInUse = true;
  client.on("error", (err) =>{
    console.log("Error" + err);
    global.redisInUse = false;});
    return client;
}

let getClient = () => {
  let client = redis.createClient(6379, '127.0.0.1', {"password":"1zHyBRMvAVA@s@%bu3Z"});
  global.redisInUse = true;
  client.on("error", (err) =>{
    console.log("Error" + err);
    global.redisInUse = false;});
    return client;
}

let redisPassword = "1zHyBRMvAVA@s@%bu3Z"
exports.init = () => {
    global.redisInUse = false;
    let client = redis.createClient(6379, '127.0.0.1', {"password":redisPassword});
    let netclient = new net.Socket().connect(PORT, HOST);
    client.on("error", (err) =>{
    console.log("Error" + err);
    global.redisInUse = false;});
    	netclient.on('data', (data) => {
        client.flushdb((err, success) => {
          if(err) {
            console.log("Redis failure: " + err);
            global.client == null;
            global.redisInUse = false;
            return
          }
          let reply = "" + data;
          let stringed = JSON.parse(reply);
		    let jsonReply = JSON.parse(stringed);
          for (let i = 0; i < jsonReply["threads"].length; i++) {
            client.lpush(prefix + "threads", JSON.stringify(jsonReply["threads"][i]));
          }
          for(let j = 0; j < jsonReply["usernames"].length; j++) {
            client.sadd(prefix + "usernames", jsonReply['usernames'][j]['username']);
            client.sadd(prefix + "email", jsonReply['usernames'][j]['email']);
          }
          global.redisInUse = true;
        })  
			netclient.end();
    	})
    
    let request = {"module": "ha_index", "function": "prepare_cache", "arg": [0, 200, 0]};
		let buf = new Buffer(JSON.stringify(request));
    netclient.write(buf);
}


exports.checkUsername = (username) => {
  let client = getClient();
  client.sismember(prefix + "usernames", username, (err, reply) =>{
        if(reply) {
          debugger;
    return true;
    }
    else {
    return false;
    }
})
}

exports.register = (username) => {let client = getClient();client.sadd(prefix + "usernames", username);}