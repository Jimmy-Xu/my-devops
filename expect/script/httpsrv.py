import SimpleHTTPServer, SocketServer
import urlparse

PORT = 8888

class MyTCPServer(SocketServer.TCPServer):
    allow_reuse_address = True

class MyHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
   def do_GET(self):
       # Parse query data & params to find out what was passed
       parsedParams = urlparse.urlparse(self.path)
       queryParsed = urlparse.parse_qs(parsedParams.query)

       print "parsedParams.path[-3:]", parsedParams.path[-3:]
       if parsedParams.path[-3:] == "log":
           filename = parsedParams.path[1:]
           #self.processMyRequest(filename)
           SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self);
       else:
          # Default to serve up a local file
          SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self);

   # def processMyRequest(self, query):
   #     self.send_response(200)
   #     self.send_header('Content-Type', 'text/plain')
   #     self.end_headers()
   #
   #     self.wfile.write("<?xml version='1.0'?>");
   #     self.wfile.write("<sample>"+query+"</sample>");
   #     self.wfile.close();

Handler = MyHandler

httpd = MyTCPServer(("0.0.0.0", PORT), Handler)

print "serving at port", PORT
httpd.serve_forever()
