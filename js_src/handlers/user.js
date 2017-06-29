'use strict'
let User = require('../models/user.js');
let crypto = require('crypto');

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
        if(username.length < 40 && username.length >3 && nickname.length < 40 && nickname.length > 3) {
            if(isNaN(username)) {
                if(password.length >= 8 && password.length <= 20) {
                    let reg = /^(\w)+(\.\w+)*@(\w)+((\.\w{2,3}){1,3})$/;
                    if (reg.test(email)) {
                        User.register(username, password, nickname, email, (model) => {
                        let stringed = JSON.parse(model);
		                let viewModel = JSON.parse(stringed);
                        if(viewModel['error'] == 'repeatusername') {
                            res.writeHead(400, {});
                            let jsonData = {"errorcode": 4};
                            res.write(JSON.stringify(jsonData));
                            res.end();
                        }
                        else if(viewModel['error'] == 'repeatemail') {
                            res.writeHead(400, {});
                            let jsonData = {"errorcode": 5};
                            res.write(JSON.stringify(jsonData));
                            res.end();
                        }
                        else{
		                res.send(viewModel);}})
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
                errorReport(6);
            }
       }
        else {
        errorReport(1);
        }

        
}

exports.login = (req, res) => {
    let username = req.body.username;
    let password = req.body.password;
    let ispublic = req.body.public;
    let errorReport = (errorcode) => {
        res.writeHead(400, {});
        let jsonData = {"errorcode":errorcode};
        res.write(JSON.stringify(jsonData));
        res.end();
     }
    if(username.length < 40 && username.length >3) {
        if(password.length >= 8 && password.length <= 20) {
            User.login(username, password, (model) => {
                let stringed = JSON.parse(model);
		        let viewModel = JSON.parse(stringed);
                if(viewModel['status'] == 'nouser') {
                    errorReport(1);
                }
                else if(viewModel['status'] == 'wrongpass') {
                    errorReport(2);
                }
                else {
                    let uid = viewModel['id'];
                    let md5 = crypto.createHash('md5');
                    md5.update(uid);
                    let hash = md5.digest('hex');
                    console.log(req.cookies['connect.sid']);
                        res.cookie('session', {'username': username, 'sid': hash}, {maxAge: 604800*1000});
                     req.session.username = username;
                     req.session.sid = hash;
                     res.sendStatus(200);
                }
            }
            )
        }
    }

}

exports.logout = (req, res) => {
    let logout = req.body.logout;
    if(logout) {
        req.session.destroy();
        res.cookie('session', 0, {});
        res.sendStatus(200);
    }
}

exports.checkUsername = (req, res) => {
    let username = req.body.username;
    let prefix = "ha_";
    if(redisInUse) {
        client.sismember(prefix + "usernames", username, (err, reply) =>{
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