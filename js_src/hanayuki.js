var express = require('express');
var http = require('http');
var app = express();
var dust = require('dustjs-linkedin');
var cons = require('consolidate');

app.set('port', process.env.PORT || 3000);



app.engine('dust', cons.dust);
app.set('view engine', 'dust');
app.use(express.static(__dirname + '/public'));

require('./routes.js')(app);

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