from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import JobViewSet

router = DefaultRouter()
router.register(r'jobs', JobViewSet)

urlpatterns = [
    path('', include(router.urls)),
    # Custom endpoints
    path('upload/', JobViewSet.as_view({'post': 'create'}), name='upload'),
    path('job/<uuid:pk>/', JobViewSet.as_view({'get': 'retrieve'}), name='job-status'),
    path('consent/', JobViewSet.as_view({'post': 'consent'}), name='consent'),
]
