'use strict'
let Thread = require('../models/thread.js');

exports.read = (req, res) => {
	let threadid = req.params.threadid;
	Thread.read(threadid, req.session.username, (model) => {
        let stringed = JSON.parse(model);
        let viewModel = JSON.parse(stringed);
        if(viewModel['status']) {
        	res.sendStatus(404);
        }
        viewModel.csrf = req.csrfToken();
        viewModel.loginStatus = (chunk, context, bodies, params) => {
		if(req.session.username == null) {
				return chunk.render(bodies.notLogin, context);
		}
		return true;
		}
        res.render('thread',viewModel);	
	})
}

exports.reply = (req, res) => {
	let threadid = req.params.threadid;
	let content = req.body.content;
	let username = req.session.username;
	let threadtitle = req.body.threadname;
	let errormsg = (httpcode, id) => {
		res.writeHead(httpcode, {});
		let jsonData = {
			"errorcode": id
		};
		res.write(JSON.stringify(jsonData));
		res.end();
	} 
	if (content.length > 300) {
		errormsg(400,1);
	}
	Thread.reply(threadid, content, username, threadtitle, (model) => {
		let stringed = JSON.parse(model);
		let viewModel = JSON.parse(stringed);
		if (viewModel == "error") errormsg(500, 2);
		res.sendStatus(200);
	})
}

exports.getreply = (req, res) => {
	let threadid = req.params.threadid;
	let replylist = req.body.reply;
	replylist  = JSON.parse(replylist);
	Thread.getreply(threadid, replylist, (model) => {
		let stringed = JSON.parse(model);
        let viewModel = JSON.parse(stringed);
        if(viewModel == "error") res.sendStatus(500);
        res.send(JSON.stringify(viewModel));
	})
}