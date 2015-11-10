module responses;

import std.stdio;
import std.format;
import std.algorithm;
import std.array;
import vibe.data.json;

struct Response{
	string url;
	Json response;
	int code;
	Json cookie;
}

class ResponseManager{

  public Response[] responses;

  void add(string url,Json response, int code, Json cookie){
  	responses ~= Response(url,response, code, cookie);
  }

  Response get(string url){
     Response[] matchingResponses = responses.filter!(r => r.url == url).array;
     auto length = matchingResponses.length;
     Response result = length > 0 ? matchingResponses[length-1] : Response(url, serializeToJson("url was not found in the stub"), 200, serializeToJson("no cookie"));
   	 return result;
  }

  void clear(){
   responses = [];
  }

}


