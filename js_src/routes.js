let index = require('./handlers/index.js');
let user = require('./handlers/user.js')

module.exports = (app) => {
	app.get('/', index.index);
	app.post('/thread/add', index.add);
	app.post('/user/register', user.register);
	app.post('/user/checkUsername', user.checkUsername);
}