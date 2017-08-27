'use strict'
let Thread = require('../models/thread.js');

exports.read = (req, res) => {
	let threadid = req.params.threadid;
	Thread.read(threadid, (model) => {
        let stringed = JSON.parse(model);
        let viewModel = JSON.parse(stringed);
        if(viewModel['status']) {
        	res.sendStatus(404);
        }
        res.render('thread',viewModel);	
	})
}