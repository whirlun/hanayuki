'use strict'
let Index = require('../models/index.js');

exports.index = (req, res) => {
	let index, offset;
	let prefix = "ha_";
	isNaN(req.query.index) ? index = 0 : index = req.query.index;
	isNaN(req.query.offset) ? offset=20 :offset = req.query.offset;
	offset > 20 ? offset = 20 : offset;
	if (index+offset < 200 && redisInUse == true) {
		client.lrange(prefix + "threads", 200 - index-offset, 200-index+1, (err, threadList) => {
		let viewModal = new Object();
		let temp = [];
		for(let i = 0; i < threadList.length; i++) {		
			temp[i] = JSON.parse(threadList[i]);
		}
		viewModal.threads = temp.reverse();
		viewModal.csrf = req.csrfToken();
		viewModal.loginStatus = (chunk, context, bodies, params) => {
			if(req.session.username == null) {
				return chunk.render(bodies.notLogin, context);
			}
			return true;
		}
		res.render('index', viewModal);		
		})
	}
	else {
	Index.renderIndex(parseInt(index),parseInt(offset), (model) =>
		{let stringed = JSON.parse(model);
		let	viewModel = JSON.parse(stringed);
		viewModel.csrf = req.csrfToken();
		viewModel.loginStatus = (chunk, context, bodies, params) => {
			if(req.session.username == null) {
				return chunk.render(bodies.notLogin, context);
			}
			return true;
		}
		res.render('index', viewModel);
	}
	)
	}
}

exports.add = (req, res) => {
	let title = req.body.title;
	let content = req.body.content;
	let category = req.body.cat;
	let accesslevel = req.body.accesslevel;
	let username = req.session.username;
	Index.addThread(title, content, username, category, accesslevel, (model) =>
	{res.send(200);
	})
}