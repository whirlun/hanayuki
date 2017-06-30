var cluster = require('cluster');
var numCPUs = require('os').cpus().length;
if(cluster.isMaster) {
    console.log('Master on');
    var redisClient = require('./models/redis.js');
    redisClient.init();
    for (var i = 0; i < numCPUs; i++) cluster.fork();
    cluster.on('listening', (worker, address) => {
        console.log('worker' + worker.process.pid + ' is started')
    });
    cluster.on('exit', (worker, code, signal) => {
        console.log('worker' + worker.process.pid + ' is restarting');
        setTimeout(() => cluster.fork(), 2000 );
    })
}else {
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
var redisStore = require('connect-redis')(session);
var cons = require('consolidate');
app.set('port', process.env.PORT || 3000);
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.engine('dust', cons.dust);
app.set('view engine', 'dust');
app.use(express.static(__dirname + '/public'));
app.use(cookieParser());
app.use(session({
    store : new redisStore({
        host: "127.0.0.1",
        port: 6379,
        pass: "1zHyBRMvAVA@s@%bu3Z",
        db: 1,
        prefix: "ha_"
    }),
     resave: true,
    saveUninitialized: false,
    cookie: {maxAge: 604800*1000},
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
var redisClient = require('./models/redis.js');
global.client = redisClient.getClient();

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
}