import json

class Resp():
	def __init__(self, code, message, data):
		self.code = code
		self.message = message
		self.data = data

	def toJsonString(self):
		return json.dumps(self, default=lambda o: o.__dict__, sort_keys=True, indent=4)
