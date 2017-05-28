# hanayuki
Hanayuki, a forum system based on erlang and node


To Compile java, use command javac -classpath OtpErlang.jar:mongo-java.jar *.java

To run it, use command java -Djava.ext.dirs=./ MongoNode Nodename CookieName DataBaseName

to compile Erlang, use erlc -o ebin ./src/*.erl

to run Erlang, use erl -pa ebin -pa ./lib/jiffy/ebin -sname Nodename -setcookie CookieName

to run Node.JS, use node hanayuki.js