# -*- coding: UTF-8 -*-

from django.http import HttpResponse, StreamingHttpResponse
from django.conf import settings
import logging
import os

logger = logging.getLogger('log')

count = 0

def getTape(request):
	tapePath = '/opt/gbase8s/tape'

	global count 
	count += 1

	tapeName = 'tape' + str(count) + '_l0'
	tapeFullName = os.path.join(tapePath, tapeName)

	logger.info(count)

	#重新生成备份文件
	os.system('source /env.sh && ontape -s -L 0 -t STDIO > ' + tapeFullName)

	#发送备份文件
	try:
		fTape = open(tapeFullName, 'rb')
	except Exception, e:
		logger.error(str(e))
		return HttpResponse("")
	else:
		response = StreamingHttpResponse(fTape)
		response['Content-Type'] = 'application/octet-stream'
		response['Content-Disposition'] = 'attachment;filename="%s"' % tapeName
		#删除备份文件
		try:
			os.remove(tapeFullName)
		except Exception, e:
			logger.error(str(e))
		return response
	
