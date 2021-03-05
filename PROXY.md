# TODO HTTP getblocktemplate
POST / HTTP/1.1
Authorization: Basic c2RmZzpzZHJ0
Host: 192.168.1.32:3000
Accept: */*
Accept-Encoding: deflate, gzip
Content-type: application/json
X-Mining-Extensions: longpoll midstate rollntime submitold
Content-Length: 235
User-Agent: bfgminer/5.4.2-unknown

{"id": 0, "method": "getblocktemplate", "params": [{"capabilities": ["coinbasetxn", "workid", "longpoll", "coinbase/append", "time/increment", "version/force", "version/reduce", "submit/coinbase", "submit/truncate"], "maxversion": 4}]}';


# TODO HTTP getwork
POST / HTTP/1.1
Authorization: Basic c2RmZzpzZHJ0
Host: 192.168.1.32:3000
Accept: */*
Accept-Encoding: deflate, gzip
Content-type: application/json
X-Mining-Extensions: longpoll midstate rollntime submitold
Content-Length: 44
User-Agent: bfgminer/5.4.2-unknown

{"method": "getwork", "params": [], "id":0}

# TODO TCP mining.subscribe

{"id": 0, "method": "mining.subscribe", "params": ["bfgminer/5.4.2-unknown"]}
{"id": 1, "method": "mining.subscribe", "params": []}
