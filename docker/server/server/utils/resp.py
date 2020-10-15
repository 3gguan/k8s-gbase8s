import json

class Resp():
	def __init__(self, code, message, data):
		self.code = code
		self.message = message
		self.data = data

	def toDict(self):
		dict = {}
		dict.update(self.__dict__)
		return dict

	def toJsonString(self):
		return json.dumps(self.toDict(), ensure_ascii=False)
