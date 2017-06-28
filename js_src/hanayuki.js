var express = require('express');
var http = require('http');
var app = express();
var dust = require('dustjs-linkedin');
var cookieParser = require('cookie-parser');
var session = require('express-session');
var csrf = require('csurf');
var bodyParser = require('body-parser');
require('dustjs-helpers');
require('moment');
require('dustjs-helper-formatdate');
var cons = require('consolidate');
app.set('port', process.env.PORT || 3000);
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.engine('dust', cons.dust);
app.set('view engine', 'dust');
app.use(express.static(__dirname + '/public'));
app.use(cookieParser());
app.use(session({
     resave: false,
    saveUninitialized: false,
    secret: "ddddddddd"
}));

var csrfWhitelist = (req, res, next) =>{
var csrfEnabled = true;
var whitelist = new Array("/user/checkusername");
if (whitelist.indexOf(req.path) != -1) {
    csrfEnabled = false;
}
if (csrfEnabled) {
    csrf()(req, res, next);
}else {
    next();
}
}

app.use(csrfWhitelist);
require('./routes.js')(app);
redisClient = require('./models/redis.js');
global.client = redisClient.init();

var server;

function startServer() {
    server = http.createServer(app).listen(app.get('port'), function(){
      console.log( 'Express started in ' + app.get('env') +
        ' mode on http://localhost:' + app.get('port') +
        '; press Ctrl-C to terminate.' );
    });
}

if(require.main === module){
    // application run directly; start app server
    startServer();
} else {
    // application imported as a module via "require": export function to create server
    module.exports = startServer;
}