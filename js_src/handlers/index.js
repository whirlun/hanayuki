'use strict'
let Index = require('../models/index.js');


exports.index = (req, res) => {
	let index, offset;
	isNaN(req.query.index) ? index = 0 : index = req.query.index;
	isNaN(req.query.offset) ? offset=20 :offset = req.query.offset;
	offset > 100 ? offset = 20 : offset;
	Index.renderIndex(parseInt(index),parseInt(offset), (model) =>
		{let stringed = JSON.parse(model);
		let	viewModel = JSON.parse(stringed);
		viewModel.csrf = req.csrfToken();
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
		res.send(viewModel);
	})
}