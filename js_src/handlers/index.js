'use strict'
let Index = require('../models/index.js');


exports.index = (req, res) => {
	Index.renderIndex(0, 20, (model) =>
		{let stringed = JSON.parse(model);
		let	viewModel = JSON.parse(stringed);
		res.render('index', viewModel);
	}
		)
}