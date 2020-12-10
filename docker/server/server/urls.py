"""server URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.11/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from django.conf.urls import url
from django.contrib import admin

from service import hac

urlpatterns = [
    url(r'^admin/', admin.site.urls),
    url(r'^hac/getTape', hac.getTape),
    url(r'^hac/addTrustHost', hac.addTrustHost),
    url(r'^hac/connect', hac.connect),
    url(r'^hac/addSecondary', hac.connect),
    url(r'^hac/getStatus', hac.getStatus),
    url(r'^hac/exec', hac.execCmd),
]
