import vibe.d;
import responses;
import std.file;
import std.path;
import std.stdio;
import std.algorithm;
import std.array;
import std.exception;
import std.string;
import std.typecons;

ResponseManager rm;
string dataSetsDir;
string targetPrefix;

void stubApi(HTTPServerRequest req, HTTPServerResponse res)
{
    string request = req.requestURL;
    if(startsWith(req.requestURL, targetPrefix)){
      request = request.replace(targetPrefix,"");
    }

	auto data = rm.get(request);
    
    if(data.cookie != "no cookie"){
      res.setCookie(data.cookie["name"].to!string,data.cookie["value"].to!string,data.cookie["path"].to!string);
    }
    res.writeJsonBody(serializeToJson(data.response), data.code);
}

void resetData(HTTPServerRequest req, HTTPServerResponse res)
{
	rm.clear();
	res.writeJsonBody(serializeToJson(["message":"all data cleared"]));
}

void showData(HTTPServerRequest req, HTTPServerResponse res)
{
  res.writeJsonBody(serializeToJson(rm.show()));
}

void setupResponses(HTTPServerRequest req, HTTPServerResponse res)
{
	auto url = req.json["url"].to!string;
	auto response = req.json["response"];
	auto jsonCode = req.json["code"];
	auto code = (jsonCode.type != Json.Type.Undefined) ? jsonCode.to!int : 200;
	auto jsonCookie = req.json["cookie"];
	auto cookie = (jsonCookie.type != Json.Type.Undefined) ? jsonCookie : serializeToJson("no cookie");
	
	writeln("setting up response on url: " ~ url);
	
	rm.add(url, response, code, cookie);
	res.writeJsonBody(serializeToJson(rm.get(url)));
}

void setupDataset(HTTPServerRequest req, HTTPServerResponse res)
{
	auto name = req.params["dataset"].to!string ~ ".json";

    auto dataSets = dirEntries(dataSetsDir,"*.json",SpanMode.depth);
    auto dataSet = dataSets.filter!(d => d.baseName == name).array;
    if (dataSet.empty){
	  throw new Exception("Could not find a dataset named: " ~ name);
    }

    auto content = to!string(read(dataSet[0]));
    Json jsonSet = parseJson(content);

    foreach (data; jsonSet) {
		auto url = data["url"].get!string;
		auto response = data["response"];
		auto jsonCode = data["code"];
        auto code = (jsonCode.type != Json.Type.Undefined) ? jsonCode.to!int : 200;

        auto jsonCookie = data["cookie"];
	    auto cookie = (jsonCookie.type != Json.Type.Undefined) ? jsonCookie : serializeToJson("no cookie");
        rm.add(url, response, code, cookie);
	}

	res.writeJsonBody(jsonSet);
}

shared static this()
{
	string port;
	string webapp;
	string datadir;
	string prefix;
	string apiBase;
	readOption("port", &port, "Port to run on");
    readOption("webapp", &webapp, "Target Webapp directory"); 
    readOption("datadir", &datadir, "Datasets directory");
    readOption("prefix", &datadir, "Prefix");
    readOption("apiBase", &datadir, "APi base url");

    string targetWebapp = webapp.empty? "." : webapp; 
    dataSetsDir = datadir.empty? "./data" : datadir;
    targetPrefix = prefix.empty? "/cb" : prefix;
    string targetApiBase = apiBase.empty? "/cb/api/*" : apiBase;

    rm = new ResponseManager();

    auto fileServerSettings = new HTTPFileServerSettings;
    fileServerSettings.serverPathPrefix = targetPrefix;

    auto router = new URLRouter;
	router
	.get("/dataset/:dataset", &setupDataset)
	.get("/data/reset", &resetData)
	.get("/data/show", &showData)
	.post("/setup", &setupResponses)
	.any(targetApiBase, &stubApi)
	.get("/", (HTTPServerRequest req, HTTPServerResponse res) { 
			res.redirect(targetPrefix ~ "/");
		})	
	.get("*", serveStaticFiles(targetWebapp, fileServerSettings));

	auto settings = new HTTPServerSettings;
      
	settings.port = port.empty ? 8009 : to!ushort(port);
	settings.bindAddresses = ["::1", "127.0.0.1"];
	
	listenHTTP(settings, router);
}

//curl -H "Content-Type: application/json" -X POST -d '{"url":"/api/login/client/demousers", "response":[{"email" : "ant@email.com","name" : "Colin Ant 3","role" : "Client"}]}' http://localhost:8009/setup
