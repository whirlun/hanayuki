import com.ericsson.otp.erlang.*;
import java.util.concurrent.*;
import com.mongodb.MongoClient;
import com.mongodb.client.MongoDatabase;

public class MongoNode {
    private MongoClient mongoClient;
    private ExecutorService exec;
    private OtpErlangRef ref;
    private OtpNode node;
    private OtpMbox mbox;
    private MongoConnector conn;

    public MongoNode(String nodeName, String cookie, String databaseName) throws Exception{
        super();
        exec = Executors.newFixedThreadPool(10);
        node = new OtpNode(nodeName, cookie);
        mbox = node.createMbox("mongo_server");
        conn = new MongoConnector(databaseName);
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            System.out.println("wrong number of arguments");
            return;
        }
        MongoNode main = new MongoNode(args[0],args[1], args[2]);
        main.process();
    }

    private void process() {
        while (true) {
            try{
                //{Action, Pid, Ref, Setname,[keys], [values] }
                OtpErlangObject msg = mbox.receive();
                OtpErlangTuple t = (OtpErlangTuple) msg;
                String action = ((OtpErlangAtom) t.elementAt(0)).atomValue();
                OtpErlangPid from = ((OtpErlangPid) t.elementAt(1));
                OtpErlangRef ref = ((OtpErlangRef) t.elementAt(2));
                String setname = ((OtpErlangAtom)t.elementAt(3)).atomValue();
                OtpErlangList keys = ((OtpErlangList)t.elementAt(4));
                OtpErlangList values;
                OtpErlangString operation;
                MongoTask task = null;
                if(t.arity() == 7) {
                    values = ((OtpErlangList)t.elementAt(5));
                    operation = ((OtpErlangString)t.elementAt(6));
                    task = new MongoTask(mbox, conn, from, ref, setname, action, keys, values, operation);
                }
                else if(t.arity() == 6) {
                    values = ((OtpErlangList)t.elementAt(5));
                    task = new MongoTask(mbox, conn, from,ref, setname, action, keys, values, null);
                }
                else if(t.arity() == 5) {
                    task = new MongoTask(mbox, conn, from, ref, setname, action, keys, null, null);
                }
                else {
                    System.out.println("invalid request" + t);
                    continue;
                }
                exec.submit(task);
            } catch(Exception e) {
                System.out.println("Unexpected: " + e);
                e.printStackTrace();
            }
        }
    }
}