let index = require('./handlers/index.js');
let user = require('./handlers/user.js');
let thread = require('./handlers/thread.js');

module.exports = (app) => {
	app.get('/', index.index);
	app.get('/thread/:threadid', thread.read);
	app.get('/userhome/:username', user.userpage);
	app.post('/thread/add', index.add);
	app.post('/thread/:threadid/reply', thread.reply);
	app.post('/thread/:threadid/getreply', thread.getreply);
	app.post('/thread/:threadid/like', thread.like);
	app.post('/thread/:threadid/star', thread.star);
	app.post('/user/register', user.register);
	app.post('/user/login', user.login)
	app.post('/user/checkUsername', user.checkUsername);
	app.post('/user/logout', user.logout);
	app.post('/userhome/:username/activities', user.activities);
	app.post('/userhome/:username/loves', user.loves);
	app.post('/userhome/:username/replies', user.replies);
	app.post('/userhome/:username/stars', user.stars);
}