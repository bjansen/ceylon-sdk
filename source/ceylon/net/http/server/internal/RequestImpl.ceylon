import ceylon.collection { HashMap }
import ceylon.io { SocketAddress }
import ceylon.net.http.server { 
    Request, Session, 
    InternalException, HttpEndpoint }

import io.undertow.server { HttpServerExchange }
import io.undertow.server.handlers.form { FormDataParser, FormData, FormParserFactory }

import io.undertow.server.session { 
        SessionManager { smAttachmentKey=ATTACHMENT_KEY }, 
        UtSession=Session, SessionCookieConfig }
import io.undertow.util { Headers { headerConntentType=CONTENT_TYPE }, 
                         HttpString }

import java.lang { JString=String }
import java.util { Deque, JMap=Map }
import ceylon.net.http { Method }

by("Matej Lazar")
shared class RequestImpl(HttpServerExchange exchange, FormParserFactory formParserFactory, endpoint, path, method) satisfies Request {

    shared HttpEndpoint endpoint;

    shared actual String path;

    shared actual Method method;

    HashMap<String, String[]> parametersMap = HashMap<String, String[]>(); 

    variable FormData? parsedFormData = null;
    FormData formData => parsedFormData else (parsedFormData = parseFormData());

    shared actual String? header(String name) {
        return getHeader(name);
    }

    String? getHeader(String name) {
        return exchange.requestHeaders.getFirst(HttpString(name));
    }

    shared actual String[] headers(String name) {
        value headers = exchange.requestHeaders.get(HttpString(name)); //TODO HttpString not required by newer version
        SequenceBuilder<String> sequenceBuilder = SequenceBuilder<String>();
        
        value it = headers.iterator();
        while (it.hasNext()) {
            value header = it.next();
            sequenceBuilder.append(header.string);
        }
        
        return sequenceBuilder.sequence;
    }
    
    shared actual String[] parameters(String name) {

        if (parametersMap.contains(name)) {
            if (exists params = parametersMap.get(name)) {
                return params;
            }
        }

        SequenceBuilder<String> sequenceBuilder = SequenceBuilder<String>();
        value paramName = JString(name);
        JMap<JString,Deque<JString>> qp = exchange.queryParameters;

        if (qp.containsKey(paramName)) {
            Deque<JString> params = qp.get(paramName);
            value it = params.iterator();
            while (it.hasNext()) {
                value param = it.next(); 
                sequenceBuilder.append(param.string);
            }
        }

        addPostValues(sequenceBuilder, name);
        value params = sequenceBuilder.sequence;
        parametersMap.put(name, params);
        return params;
    }

    shared actual String? parameter(String name) {
        value params = parameters(name);
        if (nonempty params) {
            return params.first;
        } else {
            return null;
        }
    }

    shared actual String uri => exchange.requestURI;

    shared actual String relativePath {
        return endpoint.path.relativePath(path);
    }

    shared actual SocketAddress destinationAddress {
        value address = exchange.destinationAddress;
        return SocketAddress(address.hostString, address.port);
    }

    shared actual String queryString => exchange.queryString;

    shared actual String scheme => exchange.requestScheme;

    shared actual SocketAddress sourceAddress {
        value address = exchange.sourceAddress;
        return SocketAddress(address.hostString, address.port);
    }

    shared actual String? contentType => getHeader(headerConntentType.string);

    shared actual Session session {
        SessionManager sessionManager = exchange.getAttachment(smAttachmentKey);

        //TODO configurable session cookie
        SessionCookieConfig sessionCookieConfig = SessionCookieConfig();

        variable UtSession|Null utSession = sessionManager.getSession(exchange, sessionCookieConfig);

        if (!utSession exists) {
            utSession = sessionManager.createSession(exchange, sessionCookieConfig);
        }

        if (exists s = utSession) {
            return DefaultSession(s);
        } else {
            throw InternalException("Cannot get or create session.");
        }
    }

    void addPostValues(SequenceBuilder<String> sequenceBuilder, String paramName) {
        if (formData.contains(paramName)) {
            Deque<FormData.FormValue> params = formData.get(paramName);
            value it = params.iterator();
            while (it.hasNext()) {
                FormData.FormValue param = it.next(); 
                String? fileName = param.fileName;
                if (exists fileName) {
                    //TODO handle uploaded file	
                } else {
                    sequenceBuilder.append(param.\ivalue);
                }
            }
        }
    }

    FormData parseFormData() {
        FormDataParser? formDataParser = formParserFactory.createParser(exchange);
        if (exists fdp = formDataParser) {
            return fdp.parseBlocking();
            //TODO ASYNC parsing for async endpoint formData = fdp.parse(nextHandler);
        } else {
            //If no parser exists for requeste content-type, construct empty form data
            return FormData(1000); //TODO expose max form data values as option
        }
    }
}
