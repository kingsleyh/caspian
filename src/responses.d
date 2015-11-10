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
}

class ResponseManager{

  public Response[] responses;

  void add(string url,Json response){
  	responses ~= Response(url,response, 200);
  }

  void add(string url,Json response, int code){
  	responses ~= Response(url,response, code);
  }

  Response get(string url){
     Response[] matchingResponses = responses.filter!(r => r.url == url).array;
     auto length = matchingResponses.length;
     Response result = length > 0 ? matchingResponses[length-1] : Response(url, serializeToJson("url was not found in the stub"), 200);
   	 return result;
  }

  void clear(){
   responses = [];
  }

}


