var amqp = require('amqp');
var ctx = amqp.createConnection({url: 'amqp://hanayuki:hanayuki@localhost:5672'});
var exc;
ctx.on('error', (e) => console.log(e));
ctx.on('ready', () => {
    ctx.exchange('hanayuki-exchange', {type: 'direct', passive: true}, (exchange) => {
            exc = exchange;
            ctx.queue('js2java', (q) => {
                q.bind('hanayuki-exchange', 'js2java');
                exc.publish('js2java', {target: '首页'}, {contentEncoding: 'utf-8'});
            })
        }
    );

});

