import java.lang {
    ObjectArray
}
import java.sql {
    Connection,
    SqlArray=Array
}

class ConnectionStatus(Connection() connectionSource)
    satisfies Obtainable {

    variable Connection? conn=null;
    variable value use=0;

    "Creates a new connection if needed and returns it."
    shared Connection connection() {
        if (exists c=conn) {
            if (!c.closed) {
				use++;
                return c;
            }
        }
        conn = connectionSource();
        if (exists c=conn) {
			use++;
            return c;
        }
        throw;
    }

    shared actual void obtain() {}

    "Closes the connection if it's not being used anymore."
    shared actual void release(Throwable? error) {
        if (exists c=conn) {
			use--;
            if (use==0) { 
                c.close();
            }
        }
    }

    "Begins a transaction in the current connection."
    shared void beginTransaction() {
        connection().autoCommit=false;
    }

    "Commits the current transaction, clearing the 
     transaction flag. If an exception is thrown, the 
     transaction will be rolled back and the exception 
     rethrown."
    shared void commit() {
        try {
            connection().commit();
        } catch (Exception ex) {
            connection().rollback();
            throw ex;
        }
    }

    "Rolls back the current transaction, clearing the 
     transaction flag."
    shared void rollback() {
        connection().rollback();
    }
    
    "Forward to Connection.createSqlArray in order to convert a Java array to a java.sql.Array.  
     The caller must provide the Java array as well as the type name (ex varchar) of the database array.
     Assert that the connection exists."
    shared SqlArray createSqlArray(ObjectArray<Object> objectArray,String typeName) {
        assert (exists existingConn=conn);
        return existingConn.createArrayOf(typeName, objectArray);
    }

}
