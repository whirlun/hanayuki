'use strict'
let User = require('../models/user.js');


exports.register = (req, res) => {
    let username = req.body.username;
    let password = req.body.password;
    let email = req.body.email;
    let nickname = req.body.nickname;
     let errorReport = (errorcode) => {
        res.writeHead(400, {});
        let jsonData = {"errorcode":errorcode};
        res.write(JSON.stringify(jsonData));
        res.end();
     }
        if(username.length < 40 && nickname.length < 40) {
            if(password.length >= 8 && password.length <= 20) {
                let reg = /^(\w)+(\.\w+)*@(\w)+((\.\w{2,3}){1,3})$/;
                if (reg.test(email)) {
                    User.register(username, password, email, nickname, (model) => {
                    let stringed = JSON.parse(model);
		            let viewModel = JSON.parse(stringed);
		            res.send(viewModel);})
                }
                else {
                errorReport(3)
            };
            }
            else {
                errorReport(2);
            }
        }
        else {
            errorReport(1);
        }

        
}

exports.checkUsername = (req, res) => {
    let username = req.body.username;
    if(redisInUse) {
        client.sismember("usernames", username, (err, reply) =>{
        if(reply) {
        let jsonData = {"repeat": true};
        res.send(JSON.stringify(jsonData));
    }
else {
    let jsonData = {"repeat": false};
    res.send(JSON.stringify(jsonData));
}});
    }
}