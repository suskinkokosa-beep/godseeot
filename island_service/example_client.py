#!/usr/bin/env python3
import requests, json, sys
BASE = sys.argv[1] if len(sys.argv)>1 else 'http://localhost:5000'
owner = 'alice'
r = requests.get(f'{BASE}/island/{owner}')
print('GET /island/alice =>', r.status_code)
print(r.json())
