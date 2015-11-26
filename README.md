# Caspian - Fake HTTP Server

Caspian is an http server which hosts your javascript webapp and responds to http calls made to the caspian server with json responses of your choice.

### Running

You start Caspian on the command line and give it the following options:

* --port 
* --webapp
* --datadir

The port is the port caspian will start on. You provide a path to the root of your javascript front end to webapp. The datadir is used to supply canned responses for urls that your client might call.

       caspian --port 8001 --webapp ~/dev/myapp/webapp --datadir ~/dev/myapp/tests/data
       
There are 2 ways to set up json responses:

* Using the GET to http://localhost:8001/dataset/name_of_file 
* Using a dynamic POST to http://localhost:8001/setup

In the GET version (I know in REST it should be PUT but the ease of use took precedence) you supply json responses in the datadir directory in json format like this:

        // contents of file: ~/some/path/data/login.json
        [
          {"url":"/api/something".
           "response": [{name: caspian},{name: superman}],
           "code": 200,
           "cookie": {
             "name":"my cookie",
             "value":"somevalue",
             "path":"/"
           } 
          }
        ]

http GET for this file:

        http://localhost:8001/dataset/login

In the json array you can have as many or as few responses as you like and you dynamically override them by using option 2 the dynamic POST.

The code and cookie are optional. If not included it defaults to status code 200 and no cookie is created.

In the POST version you just need to make a post request with the json in the body e.g.:

        curl -H "Content-Type: application/json" -X POST -d '{"url":"/api/login/user", "response":[{"email" : "superman@krypton.com","name" : "Superman","role" : "Saviour"}]}' http://localhost:8001/setup

You can also view all the setup data via a GET 

        http://localhost:8001/data/show

And you can clear the data via a GET (same reason for GET over DELETE as before)

        http://localhost:8001/data/reset
        
### Background

This server was originally designed to test a SPA javascript application using CasperJS where any scenario could be manufactured to test the javascript client. With the added benefit in being able to run tests against a real environment as well (if tests are written carefully) by just not doing the stub data steps.
