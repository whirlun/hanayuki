'use strict'
let Index = require('../models/index.js');

exports.index = (req, res) => {
	let index, offset;
	let prefix = "ha_";
	isNaN(req.query.index) ? index = 0 : index = req.query.index;
	isNaN(req.query.offset) ? offset=20 :offset = req.query.offset;
	offset > 20 ? offset = 20 : offset;
	offset <= 0 ? offset = 20 : offset;
	Index.renderIndex(parseInt(index),parseInt(offset), req.session.username, (model) =>
		{let stringed = JSON.parse(model);
		let	viewModel = JSON.parse(stringed);
		if(viewModel == "error") res.sendStatus(500);
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

exports.add = (req, res) => {
	let title = req.body.title;
	let content = req.body.content;
	let category = req.body.cat;
	let accesslevel = req.body.accesslevel;
	let username = req.session.username;
	Index.addThread(title, content, username, category, accesslevel, (model) =>
	{
		let stringed = JSON.parse(model);
		let viewModel = JSON.parse(stringed);
		if (viewModel == "error") res.sendStatus(500);
		res.sendStatus(200);
	})
}