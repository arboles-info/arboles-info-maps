"""
URL configuration for arboles_info_project project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('maps.urls')),
]

# Servir archivos estáticos en desarrollo
if settings.DEBUG:
    # Servir desde STATICFILES_DIRS (desarrollo)
    for static_dir in settings.STATICFILES_DIRS:
        urlpatterns += static(settings.STATIC_URL, document_root=static_dir)
    # También servir desde STATIC_ROOT si existe y tiene contenido
    import os
    static_root = settings.STATIC_ROOT
    if os.path.exists(static_root) and os.path.isdir(static_root):
        try:
            if os.listdir(static_root):
                urlpatterns += static(settings.STATIC_URL, document_root=static_root)
        except OSError:
            pass
