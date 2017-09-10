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

exports.replythread = (req, res) => {
	let threadid = req.body.threadid;
	let content = req.body.content;
	let username = req.session.username;
	Thread.replythread(threadid, content, username, (model) => {
		let stringed = JSON.parse(model);
		let viewModel = JSON.parse(stringed);
		if (viewModel == "error") res.sendStatus(500);
		res.sendStatus(200);
	})
}