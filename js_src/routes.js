var index = require('./handlers/index.js');

module.exports = (app) => {
	app.get('/', index.index);
}