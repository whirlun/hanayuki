import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

import com.ericsson.otp.erlang.*;
import org.bson.AbstractBsonReader.State;
import org.bson.*;
import org.bson.json.JsonReader;

public class MongoTask implements Runnable {
    private OtpMbox mbox;
    private MongoConnector conn;
    private OtpErlangRef ref;
    private OtpErlangPid from;
    private String action;
    private String setname;
    private OtpErlangList keys;
    private OtpErlangList values;
    private OtpErlangString operation;
    public MongoTask(OtpMbox mbox, MongoConnector conn, OtpErlangPid from, OtpErlangRef ref, String setname, String action,
                     OtpErlangList keys, OtpErlangList values, OtpErlangString operation) {
        super();
        this.mbox = mbox;
        this.conn = conn;
        this.from = from;
        this.ref = ref;
        this.action = action;
        this.setname = setname;
        this.keys = keys;
        this.values = values;
        this.operation = operation;
    }

    private enum actions {
        INSERT, REMOVE, FIND, UPDATE, LATESTTHREAD, PREPARECACHE;
    }

    public void run() {
        actions dbaction = actions.valueOf(action.toUpperCase());
        try {
            switch(dbaction) {
                case INSERT:
                    doInsert();
                    break;
                case REMOVE:
                    doRemove();
                    break;
                case FIND:
                    doFind();
                    break;
                case UPDATE:
                    doUpdate();
                    break;
                case LATESTTHREAD:
                    doLatestThread();
                    break;
                case PREPARECACHE:
                    doPrepareCache();
            }}catch (Exception e){
            OtpErlangTuple reply = new OtpErlangTuple(new OtpErlangObject[] {
                    new OtpErlangAtom("reply"), new OtpErlangAtom("error"), ref
            });
            mbox.send(from, reply);
            System.out.println("caught error: " + e);
            e.printStackTrace();
        }
    }


    private void doInsert() throws Exception {
        conn.insert(setname, keys, values);
        OtpErlangTuple reply = new OtpErlangTuple(new OtpErlangObject[] {
                new OtpErlangAtom("reply"), new OtpErlangAtom("ok"), ref
        });
        mbox.send(from, reply);
    }

    private void doRemove() throws Exception {
        conn.remove(setname, keys, values);
        OtpErlangTuple reply = new OtpErlangTuple(new OtpErlangObject[] {
                new OtpErlangAtom("reply"), new OtpErlangAtom("ok"), ref
        });
        mbox.send(from, reply);
    }

    private void doFind() throws Exception {
        ArrayList<OtpErlangObject> arrayList = new ArrayList<>();
        List<Document> result;
        result = conn.find(setname, keys, values);
        for (Document doc:result){
            arrayList.add(java2Erlang(doc));
        }
        OtpErlangObject[] erlangArray = new OtpErlangObject[arrayList.size()];
        arrayList.toArray(erlangArray);
        OtpErlangTuple reply = new OtpErlangTuple(new OtpErlangObject[] {
                new OtpErlangAtom("reply"), new OtpErlangAtom("ok"), new OtpErlangTuple(erlangArray), ref
        });
        mbox.send(from, reply);
    }

    private void doUpdate() throws Exception {
        conn.update(setname, keys, values, operation);
        OtpErlangTuple reply = new OtpErlangTuple(new OtpErlangObject[] {
                new OtpErlangAtom("reply"), new OtpErlangAtom("ok"), ref
        });
        mbox.send(from, reply);
    }

    private void doLatestThread() throws Exception {
        ArrayList<OtpErlangObject> arrayList = new ArrayList<>();
        List<Document> result;
        result = conn.latestThread(setname, keys, values);
        for (Document doc:result){
            arrayList.add(java2Erlang(doc));
        }
        OtpErlangObject[] erlangArray = new OtpErlangObject[arrayList.size()];
        arrayList.toArray(erlangArray);
        OtpErlangTuple reply = new OtpErlangTuple(new OtpErlangObject[] {
                new OtpErlangAtom("reply"), new OtpErlangAtom("ok"), new OtpErlangList(erlangArray), ref
        });
        mbox.send(from, reply);
    }

    private void doPrepareCache() throws Exception {
        ArrayList<OtpErlangObject> threadList = new ArrayList<>();
        ArrayList<OtpErlangObject> usernameList = new ArrayList<>();
        ArrayList<OtpErlangObject> erlangResult = new ArrayList<>();
        HashMap<String, List<Document>> result = new HashMap<>();
        result = conn.prepareCache(setname, keys, values);
        List<Document> threads = result.get("thread");
        List<Document> usernames = result.get("username");
        result = null;
        for(Document thread:threads){
            threadList.add(java2Erlang(thread));
        }
        threads = null;
        for(Document username:usernames){
            usernameList.add(java2Erlang(username));
        }
        usernames = null;
        OtpErlangObject[] threadArray = new OtpErlangObject[threadList.size()];
        threadList.toArray(threadArray);
        OtpErlangList erlangThreadList = new OtpErlangList(threadArray);
        threadArray = null;
        OtpErlangObject[] userArray = new OtpErlangObject[usernameList.size()];
        usernameList.toArray(userArray);
        OtpErlangList erlangUserList = new OtpErlangList(userArray);
        userArray = null;
        erlangResult.add(new OtpErlangAtom("thread"));
        erlangResult.add(erlangThreadList);
        erlangResult.add(new OtpErlangAtom("username"));
        erlangResult.add(erlangUserList);
        OtpErlangObject[] erlangArray = new OtpErlangObject[erlangResult.size()];
        erlangResult.toArray(erlangArray);
        OtpErlangTuple reply = new OtpErlangTuple(new OtpErlangObject[] {
                new OtpErlangAtom("reply"), new OtpErlangAtom("ok"), new OtpErlangTuple(erlangArray), ref
        });        
        mbox.send(from, reply);
    }

        private enum JavaTypes {
        STRING, DOUBLE, FLOAT, INTEGER, LONG, LIST, DOCUMENT, ARRAYLIST;
    }

    private OtpErlangObject java2Erlang(Object javaTerm) {
        OtpErlangObject result = null;
        String type = javaTerm.getClass().toString();
        String[] typeSplit = type.split("\\.");
        JavaTypes javaType = JavaTypes.valueOf(typeSplit[2].toUpperCase());
        switch(javaType) {
            case STRING:
                result = java2Erlang((String)javaTerm);
                break;
            case DOUBLE:
                result = java2Erlang((Double)javaTerm);
                break;
            case FLOAT:
                result = java2Erlang((Float)javaTerm);
                break;
            case INTEGER:
                result = java2Erlang((Integer)javaTerm);
                break;
            case LONG:
                result = java2Erlang((Long)javaTerm);
                break;
            case LIST:
                result = java2Erlang((List)javaTerm);
                break;
            case DOCUMENT:
                result = java2Erlang((Document)javaTerm);
                break;
            case ARRAYLIST:
                result = java2Erlang((List)javaTerm);
        }
        return result;
    }
    private OtpErlangLong java2Erlang(Long javaTerm) { return new OtpErlangLong(javaTerm);}
    private OtpErlangString java2Erlang(String javaTerm) { return new OtpErlangString(javaTerm);}
    private OtpErlangInt java2Erlang(Integer javaTerm) { return new OtpErlangInt(javaTerm);}
    private OtpErlangFloat java2Erlang(Float javaTerm) { return new OtpErlangFloat(javaTerm);}
    private OtpErlangDouble java2Erlang(Double javaTerm) { return new OtpErlangDouble(javaTerm);}
    private OtpErlangAtom java2Erlang(BsonString javaTerm) {
        return new OtpErlangAtom(javaTerm.getValue());
    }
    private OtpErlangDouble java2Erlang(BsonDouble javaTerm) {
        return new OtpErlangDouble(javaTerm.getValue());
    }
    private OtpErlangInt java2Erlang(BsonInt32 javaTerm) {
        return new OtpErlangInt(javaTerm.getValue());
    }
    private OtpErlangLong java2Erlang(BsonInt64 javaTerm) {
        return new OtpErlangLong(javaTerm.getValue());
    }
    private OtpErlangList java2Erlang(BsonArray javaTerm) {
        ArrayList<OtpErlangObject> arrayList = new ArrayList<>();
        for (BsonValue term:javaTerm) {
            arrayList.add(java2Erlang(term));
        }
        OtpErlangObject[] erlangArray = new OtpErlangObject[arrayList.size()];
        arrayList.toArray(erlangArray);
        return new OtpErlangList(erlangArray);
    }
    private OtpErlangList java2Erlang(List javaTerm) {
        ArrayList<OtpErlangObject> arrayList = new ArrayList<>();
        for (Object term:javaTerm) {
            arrayList.add(java2Erlang(term));
        }
        OtpErlangObject[] erlangArray = new OtpErlangObject[arrayList.size()];
        arrayList.toArray(erlangArray);
        return new OtpErlangList(erlangArray);
    }
    private OtpErlangTuple java2Erlang(Document javaTerm) {
        AbstractBsonReader reader = new JsonReader(javaTerm.toJson());
        ArrayList<OtpErlangObject> arrayList = new ArrayList<>();
        reader.readStartDocument();
        Boolean breakFlag = false;
        while(true) {
            while (reader.getState() == State.TYPE && reader.readBsonType() != BsonType.END_OF_DOCUMENT) {
                String fieldName = reader.readName();
                arrayList.add(new OtpErlangAtom(fieldName));

                switch (reader.getCurrentBsonType()) {
                        case INT32:
                            arrayList.add(new OtpErlangInt(reader.readInt32()));
                            break;
                        case INT64:
                            arrayList.add(new OtpErlangLong(reader.readInt64()));
                            break;
                        case STRING:
                            arrayList.add(new OtpErlangString(reader.readString()));
                            break;
                        case DOUBLE:
                            arrayList.add(new OtpErlangDouble(reader.readDouble()));
                            break;
                        case BOOLEAN:
                            arrayList.add(new OtpErlangBoolean(reader.readBoolean()));
                            break;
                        case OBJECT_ID:
                            arrayList.add(new OtpErlangString(reader.readObjectId().toHexString()));
                            break;
                        case TIMESTAMP:
                            arrayList.add(new OtpErlangInt(reader.readTimestamp().getTime()));
                            break;
                        case UNDEFINED:
                            arrayList.add(new OtpErlangAtom("nil"));
                            break;
                        case BINARY:
                            arrayList.add(new OtpErlangBinary(reader.readBinaryData().getData()));
                            break;
                        case ARRAY:
                            arrayList.add(java2Erlang((ArrayList)javaTerm.get(fieldName)));
                            break;
                        case DOCUMENT:
                            arrayList.add(java2Erlang((Document) javaTerm.get(fieldName)));

                }
            }

            if (reader.getState() == State.VALUE) {
                reader.skipValue();
            }
            else {
                reader.readEndDocument();
                break;
            }
        }

        OtpErlangObject[] resultArray = new OtpErlangObject[arrayList.size()];
        arrayList.toArray(resultArray);
        return new OtpErlangTuple(resultArray);
    }

}