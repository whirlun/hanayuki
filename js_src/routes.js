let index = require('./handlers/index.js');
let user = require('./handlers/user.js');
let thread = require('./handlers/thread.js');

module.exports = (app) => {
	app.get('/', index.index);
	app.get('/thread/:threadid', thread.read);
	app.get('/userhome/:username', user.userpage);
	app.post('/thread/add', index.add);
	app.post('/thread/:threadid/reply', thread.reply);
	app.post('/user/register', user.register);
	app.post('/user/login', user.login)
	app.post('/user/checkUsername', user.checkUsername);
	app.post('/user/logout', user.logout);
	app.post('/userhome/:username/activities', user.activities);
}