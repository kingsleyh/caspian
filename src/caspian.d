import vibe.d;
import responses;
import std.file;
import std.path;
import std.stdio;
import std.algorithm;
import std.array;
import std.exception;
import std.string;

ResponseManager rm;

void stubApi(HTTPServerRequest req, HTTPServerResponse res)
{
	auto data = rm.get(req.requestURL);
	//res.setCookie("osi","value","/cb");
    res.writeJsonBody(serializeToJson(data.response), data.code); 
}

void setupResponses(HTTPServerRequest req, HTTPServerResponse res)
{
	auto url = req.json["url"].to!string;
	auto response = req.json["response"];
	try{
            auto code = req.json["code"].to!int;
              rm.add(url, response, code);
         	 } catch {
               rm.add(url, response);
         	 } 
	
  
	res.writeJsonBody(serializeToJson(rm.get(url)));

}

void setupDataset(HTTPServerRequest req, HTTPServerResponse res)
{
	auto name = req.params["dataset"].to!string ~ ".json";

    auto dataSets = dirEntries("./dataSets","*.json",SpanMode.breadth);
    auto dataSet = dataSets.filter!(d => d.baseName == name).array;
    if (dataSet.empty){
	  throw new Exception("Could not find a dataset named: " ~ name);
    } 
	
    auto content = to!string(read(dataSet[0]));
    Json jsonSet = parseJson(content);

    foreach (data; jsonSet) {

		auto url = data["url"].get!string;
		auto response = data["response"];

         try{
            int code = data["code"].get!int;
            rm.add(url, response, code);
         	 } catch {
              rm.add(url, response);
         	 } 
	}
   
	res.writeJsonBody(jsonSet);
}

shared static this()
{
	string port;
	string webapp;
	readOption("port", &port, "Port to run on");
    readOption("webapp", &webapp, "Target Webapp directory"); 
     
    string targetWebapp = webapp.empty? "." : webapp; 

    rm = new ResponseManager();

    auto fileServerSettings = new HTTPFileServerSettings;
    fileServerSettings.serverPathPrefix = "/cb";

    auto router = new URLRouter;
	router
	.get("/dataset/:dataset", &setupDataset)
	.post("/setup", &setupResponses)
	.any("/cb/api/*", &stubApi)
	.get("/", (HTTPServerRequest req, HTTPServerResponse res) { 
			res.redirect("/cb/");
		})	
	.get("*", serveStaticFiles(targetWebapp, fileServerSettings));

	auto settings = new HTTPServerSettings;
      
	settings.port = port.empty ? 8009 : to!ushort(port);
	settings.bindAddresses = ["::1", "127.0.0.1"];
	
	listenHTTP(settings, router);
}

//curl -H "Content-Type: application/json" -X POST -d '{"url":"/api/login/client/demousers", "response":[{"email" : "ant@email.com","name" : "Colin Ant 3","role" : "Client"}]}' http://localhost:8009/setup
