/**
 * Created by kafuuchino on 2017/04/21.
 */
'use strict';
let events = require('events');
let event = new events.EventEmitter();
let index = require('./index');
var rabbit = (() => {
        var instance;
        function ctxManager(port) {
            let amqp = require('amqp');
            this.ctx = amqp.createConnection({url: 'amqp://hanayuki:hanayuki@localhost:5672'});
            this.ctx.on('error', (e) => {
                console.log('error to create rabbitmq context:', e);
            });
            this.ctx.on('ready', () => {
                this.ctx.exchange('hanayuki-exchange', {
                    type: 'direct',
                    passive: true
                }, (exchange) => {console.log('Exchange ' + exchange.name + ' is open');this.exc = exchange;});
                this.ctx.queue('java2js', (q) => {
                    q.bind('hanayuki-exchange', 'java2js', () => {
                        let queue = [];
                        index.on();
                        q.subscribe((message) => {
                            queue.push(message);
                            event.emit('addQueue');
                        });
                        event.on('addQueue', () => {
                            let orimessage = queue.pop()['data'].toString();
                            let message = eval("(" + orimessage + ")");
                            switch (message['target'][0]['target']) {
                                case "index":
                                    console.log("index");
                                    index.callIndex(message['data']);
                                    break;
                                default:
                                    console.log('no target matched')
                            }
                        })
                    })
                });
                this.ctx.queue('js2java', (q) => {
                    q.bind('hanayuki-exchange', 'js2java', () =>console.log('js2java is ready'))
                })
            })
        }

        var _static = {
            name: 'rabbit',
            getCtx:(port) => {
                if(instance === undefined) {
                    instance = new ctxManager(port);
                }
                return instance;

            },
            closeCtx: () => {
                instance.ctx.disconnect();
                instance = undefined;
            },
            publish: (message) => {
                instance.exc.publish('js2java', message, {contentEncoding: 'utf-8'});
            }
        };
        return _static;

    })
();
let rabbitctx = rabbit.getCtx(5672);

exports.publish = (message) =>{
    rabbit.publish(message);
}
