"""
URLs de la aplicación maps
"""
from django.urls import path
from . import views

app_name = 'maps'

urlpatterns = [
    path('', views.welcome, name='welcome'),
    path('mapa/', views.mapa, name='mapa'),
    path('api/trees/', views.get_trees, name='api_trees'),
    path('api/stumps/', views.get_stumps, name='api_stumps'),
    path('robots.txt', views.robots_txt, name='robots_txt'),
]


