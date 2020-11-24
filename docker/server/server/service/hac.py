# -*- coding: UTF-8 -*-

from django.http import HttpResponse, StreamingHttpResponse, JsonResponse
from django.conf import settings
from django.views.decorators.csrf import csrf_exempt
import logging
import os,socket,fcntl,json
from ..utils.resp import Resp

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
	
def addTrustHostToFile(serverName, hostName):
	hostFile = '/opt/gbase8s/etc/hostfile'
	serverName = serverName + '\n'
	hostStr = hostName + ' ' + 'gbasedbt '

	#0不变，1新增，2修改，-1出错
	status = 1

	fHost = open(hostFile, 'r+')
	fcntl.flock(fHost, fcntl.LOCK_EX)

	try:
		lines = fHost.readlines()
		for index in range(len(lines)):
			line = lines[index]
			tempList = line.split('#')
			if tempList[1] == serverName:
				if tempList[0] != hostStr:
					status = 2
					r = line.replace(tempList[0], hostStr)
					lines.remove(line)
					lines.insert(index, r)
				else:
					status = 0
				break
		if status == 1:
		   fHost.write(hostStr + '#' + serverName)
		elif status == 2:
		   fHost.seek(0, 0)
		   fHost.writelines(lines)
		   fHost.truncate()
	except Exception, e:
		logger.error(str(e))
		status = -1

	fHost.flush
	fcntl.flock(fHost, fcntl.LOCK_UN)
	fHost.close()
	return status

@csrf_exempt
def addTrustHost(request):
	if request.method == 'POST':
		#获取对端ip，并根据ip查询hostname
		xForwardedFor = request.META.get('HTTP_X_FORWARDED_FOR')
		logger.info(request.META)
		if xForwardedFor:
			ip = xForwardedFor.split(',')[0]
			logger.info('----------')
		else:
			ip = request.META.get('REMOTE_ADDR')
			logger.info('+++++++++')
		logger.info(ip)
		
		try:
			hostName = socket.gethostbyaddr(ip)[0]
		except Exception, e:
			logger.error(str(e))
			hostName = ip

		#获取serverName
		try:
			logger.info(request.body)
			jsonBody = json.loads(request.body)
			logger.info(jsonBody)
			serverName = jsonBody['serverName']
		except Exception, e:
			logger.error(str(e))
			return HttpResponse(Resp('-1', '获取serverName失败', None).toJsonString(), content_type='application/json')

		ret = addTrustHostToFile(serverName, hostName)
		if ret != -1:	
			localHostName = socket.gethostname()
			localIp = socket.gethostbyname(localHostName)
			return HttpResponse(Resp('0', '添加信任主机成功', localIp).toJsonString(), content_type='application/json')
		else:
			return HttpResponse(Resp('-1', '添加信任主机失败', None).toJsonString(), content_type='application/json')
	else:
		return HttpResponse(Resp('-1', 'method error', None), content_type='application/json')

@csrf_exempt
def addSecondary(request):
	return HttpResponse("aaa")

def connect(request):
	if request.method == 'GET':
		return JsonResponse(Resp('0', 'connect success', None).toDict())
	else:
		return JsonResponse(Resp('-1', 'method error', None).toDict())
