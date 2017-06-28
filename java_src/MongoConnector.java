import java.util.ArrayList;
import java.util.List;
import org.bson.Document;
import org.bson.types.ObjectId;
import java.util.Arrays;
import java.util.Map;
import java.util.HashMap;

import com.ericsson.otp.erlang.*;
import com.mongodb.MongoClient;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.FindIterable;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.model.Filters;
import com.mongodb.Block;
import com.mongodb.DBObject;
import static com.mongodb.client.model.Projections.*;
import static com.mongodb.client.model.Sorts.*;
import static com.mongodb.client.model.Aggregates.*;
import com.mongodb.client.AggregateIterable;
import com.mongodb.client.model.Accumulators;
import com.mongodb.client.model.Projections;
import org.bson.types.Binary;

public class MongoConnector {
    private MongoDatabase mdb;
    public MongoConnector(String databaseName) throws Exception {
        super();
        try {
            MongoClient mongoClient = new MongoClient("localhost", 27017);
            mdb = mongoClient.getDatabase(databaseName);
        }catch (Exception e) {
            System.err.println( e.getClass().getName() + ": " + e.getMessage() );
        }
    }

    public void insert(String setname,OtpErlangList keys,OtpErlangList values) throws Exception{
        Document document = new Document();
        for(int i = 0; i <keys.arity(); i++){
            OtpErlangObject key = keys.elementAt(i);
            OtpErlangObject value = values.elementAt(i);
            document.append((String)convert2Java(key), convert2Java(value));
        }
        MongoCollection<Document> collection = mdb.getCollection(setname);
        collection.insertOne(document);
    }

    public void remove(String setname,OtpErlangList keys,OtpErlangList values) throws Exception{
        MongoCollection<Document> collection = mdb.getCollection(setname);
        for(int i = 0; i <keys.arity(); i++){
            OtpErlangObject key = keys.elementAt(i);
            OtpErlangObject value = values.elementAt(i);
            collection.deleteMany(Filters.eq((String)convert2Java(key), convert2Java(value)));
        }
    }

    public List<Document> find(String setname,OtpErlangList keys, OtpErlangList values) throws Exception {
        MongoCollection<Document> collection = mdb.getCollection(setname);
        FindIterable<Document> findIterable;
        String head = (String)convert2Java(keys.getHead());
        if (head.equals("_id")) {
            findIterable = collection.find(Filters.eq(head,
                    new ObjectId((String)convert2Java(values.getHead()))));
        }
        else {
            findIterable = collection.find(Filters.eq(head,
                    (Object)convert2Java(values.getHead())));
        }
        List<Document> results = new ArrayList<>();
        for(Document result:findIterable) {
            results.add(result);
        }
        return results;
    }

    public void update(String setname,OtpErlangList keys,OtpErlangList values, OtpErlangString operation) throws Exception {
        MongoCollection<Document> collection = mdb.getCollection(setname);
        collection.updateMany(Filters.eq((String)convert2Java(keys.getHead()), convert2Java(values.getHead())),
                new Document((String)convert2Java(operation), new Document((String)convert2Java(keys.elementAt(1)), convert2Java(values.elementAt(1)))));
    }

    public List<Document> latestThread(String setname, OtpErlangList keys, OtpErlangList values) throws Exception{
        List<Document> results = new ArrayList<>();
        MongoCollection<Document> collection = mdb.getCollection(setname);
        int index = ((Long)convert2Java(values.elementAt(0))).intValue();
        int offset =((Long)convert2Java(values.elementAt(1))).intValue();
        AggregateIterable<Document> result = collection.aggregate(Arrays.asList(sort(orderBy(descending("time"))),
                skip(index),
                limit(offset)));
        for(Document doc:result) {
            results.add(doc);
        }
        return results;
    }

    public HashMap<String, List<Document>> prepareCache(String setname, OtpErlangList keys, OtpErlangList values) throws Exception{
        HashMap<String, List<Document>> result = new HashMap<>();
        List<Document> threadResult = new ArrayList<>();
        List<Document> userResult = new ArrayList<>();
        MongoCollection<Document> userCollection = mdb.getCollection(setname);
        int userTime = ((Long)convert2Java(values.elementAt(2))).intValue();
        threadResult = latestThread("thread", keys, values);
        AggregateIterable<Document> rawUserResult = userCollection.aggregate(Arrays.asList(match(Filters.gte("registertime", userTime)), 
                                                                                            project(fields(include("username")))));
        for(Document doc:rawUserResult) {
            userResult.add(doc);
        }
        result.put("thread", threadResult);
        result.put("username", userResult);
        return result;
    }

    private enum OtpTypes {
        OTPERLANGATOM, OTPERLANGBYTE, OTPERLANGCHAR, OTPERLANGDOUBLE, OTPERLANGFLOAT,
        OTPERLANGINT, OTPERLANGLIST, OTPERLANGLONG, OTPERLANGUINT, OTPERLANGUSHORT,
        OTPERLANGTUPLE, OTPERLANGSHORT,OTPERLANGSTRING, OTPERLANGBINARY
    }

    private Object convert2Java(OtpErlangObject erlangObject) throws Exception {
        Object result = null;
        String type = erlangObject.getClass().toString();
        String[] typeSplit = type.split("\\.");
        OtpTypes otpTypes = OtpTypes.valueOf(typeSplit[4].toUpperCase());
        switch(otpTypes) {
            case OTPERLANGATOM:
                result = convert2Java((OtpErlangAtom)erlangObject);
                break;
            case OTPERLANGFLOAT:
                result = convert2Java((OtpErlangFloat) erlangObject);
                break;
            case OTPERLANGDOUBLE:
                result = convert2Java((OtpErlangDouble)erlangObject);
                break;
            case OTPERLANGBYTE:
                result = convert2Java((OtpErlangByte)erlangObject);
                break;
            case OTPERLANGCHAR:
                result = convert2Java((OtpErlangChar)erlangObject);
                break;
            case OTPERLANGINT:
                result = convert2Java((OtpErlangInt)erlangObject);
                break;
            case OTPERLANGLONG:
                result = convert2Java((OtpErlangLong)erlangObject);
                break;
            case OTPERLANGSHORT:
                result = convert2Java((OtpErlangShort)erlangObject);
                break;
            case OTPERLANGTUPLE:
                result = convert2Java((OtpErlangTuple)erlangObject);
                break;
            case OTPERLANGUINT:
                result = convert2Java((OtpErlangUInt)erlangObject);
                break;
            case OTPERLANGUSHORT:
                result = convert2Java((OtpErlangUShort)erlangObject);
                break;
            case OTPERLANGLIST:
                result = convert2Java((OtpErlangList)erlangObject);
                break;
            case OTPERLANGSTRING:
                result = convert2Java((OtpErlangString)erlangObject);
                break;
            case OTPERLANGBINARY:
                result = convert2Java((OtpErlangBinary)erlangObject);
                break;
        }
        return result;
    }
    private String convert2Java(OtpErlangAtom erlangObject) throws Exception {
        return (String)erlangObject.atomValue();
    }
    private String convert2Java(OtpErlangString erlangObject) throws Exception {
        return (String)erlangObject.stringValue();
    }
    private Binary convert2Java(OtpErlangBinary erlangObject) throws Exception {
        byte[] binaryData = erlangObject.binaryValue();
        return new Binary(binaryData);
        
    }
    private Float convert2Java(OtpErlangFloat erlangObject) throws Exception {
        return (Float)erlangObject.floatValue();
    }
    private Double convert2Java(OtpErlangDouble erlangObject) throws Exception {
        return (Double)erlangObject.doubleValue();
    }
    private Integer convert2Java(OtpErlangByte erlangObject) throws Exception {
        return (Integer)erlangObject.intValue();
    }
    private Integer convert2Java(OtpErlangChar erlangObject) throws Exception {
        return (Integer)erlangObject.intValue();
    }
    private Integer convert2Java(OtpErlangShort erlangObject) throws Exception {
        return (Integer)erlangObject.intValue();
    }
    private Integer convert2Java(OtpErlangUShort erlangObject) throws Exception {
        return (Integer)erlangObject.intValue();
    }
    private Integer convert2Java(OtpErlangInt erlangObject) throws Exception {
        return (Integer)erlangObject.intValue();
    }
    private Integer convert2Java(OtpErlangUInt erlangObject) throws Exception {
        return (Integer)erlangObject.intValue();
    }
    private Long convert2Java(OtpErlangLong erlangObject) throws Exception {
        return (Long)erlangObject.longValue();
    }
    private ArrayList<Object> convert2Java(OtpErlangList erlangObject) throws Exception {
        ArrayList<Object> resultlist = new ArrayList<>();
        for(OtpErlangObject term:erlangObject) {
            resultlist.add(convert2Java(term));
        }
        return resultlist;
    }
    private Document convert2Java(OtpErlangTuple erlangObject) throws Exception {
        Document document = new Document();
        String key;
        Object value;
        if (erlangObject.arity()%2 != 0) {
            throw new IllegalArgumentException();
        }
        for(int i = 0; i < erlangObject.arity(); i++) {
            if (i%2 == 0) {
                key = (String)convert2Java(erlangObject.elementAt(i));
                value = convert2Java(erlangObject.elementAt(i+1));
                document.append(key, value);
            }
            else {
                continue;
            }
        }
        return document;
    }
}