from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.content.models import ContentStatus, Episode, Series
from apps.users.models import ProducerProfile, User, UserRole


class ContentApiTests(APITestCase):
    def setUp(self):
        self.viewer = User.objects.create_user(
            email='viewer@example.com', password='Passw0rd!123', full_name='Viewer'
        )
        self.producer = User.objects.create_producer(
            email='producer@example.com', password='Passw0rd!123', full_name='Producer'
        )
        self.profile = ProducerProfile.objects.create(
            user=self.producer, studio_name='Test Studio'
        )
        self.admin = User.objects.create_superuser(
            email='admin@example.com', password='Passw0rd!123', full_name='Admin'
        )
        self.series = Series.objects.create(
            producer=self.profile,
            title='Test Series',
            description='A sufficiently long test series description.',
            status=ContentStatus.DRAFT,
            is_free=True,
        )
        self.episode = Episode.objects.create(
            series=self.series,
            episode_number=1,
            title='Episode One',
            video_url='https://cdn.example.test/episode.m3u8',
            duration_secs=60,
        )

    def test_producer_episode_list_includes_editable_video_url(self):
        self.client.force_authenticate(self.producer)
        response = self.client.get(
            reverse('episode-list', kwargs={'series_id': self.series.id})
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['results'][0]['video_url'], self.episode.video_url)

    def test_free_viewer_can_save_clamped_progress_and_resume(self):
        self.series.status = ContentStatus.PUBLISHED
        self.series.published_at = timezone.now()
        self.series.save(update_fields=['status', 'published_at'])
        self.client.force_authenticate(self.viewer)

        response = self.client.post(
            reverse('episode-progress', kwargs={'episode_id': self.episode.id}),
            {'progress_secs': 1000, 'completed': False},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['completed'])

        resume = self.client.get(
            reverse('episode-progress', kwargs={'episode_id': self.episode.id})
        )
        self.assertEqual(resume.status_code, status.HTTP_200_OK)
        self.assertEqual(resume.data['progress_secs'], 60)
        self.assertTrue(resume.data['completed'])

    def test_premium_viewer_is_denied_stream_and_progress_without_access(self):
        self.series.is_free = False
        self.series.price = '99.00'
        self.series.status = ContentStatus.PUBLISHED
        self.series.save(update_fields=['is_free', 'price', 'status'])
        self.client.force_authenticate(self.viewer)

        stream = self.client.get(
            reverse('episode-stream', kwargs={'episode_id': self.episode.id})
        )
        progress = self.client.post(
            reverse('episode-progress', kwargs={'episode_id': self.episode.id}),
            {'progress_secs': 10},
            format='json',
        )
        self.assertEqual(stream.status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(progress.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_stats_and_users_are_available_to_admin(self):
        self.client.force_authenticate(self.admin)
        stats = self.client.get(reverse('admin-stats'))
        users = self.client.get(reverse('admin-users'))
        self.assertEqual(stats.status_code, status.HTTP_200_OK)
        self.assertEqual(stats.data['total_users'], 3)
        self.assertEqual(users.status_code, status.HTTP_200_OK)
        self.assertIn('is_active', users.data['results'][0])

    def test_viewer_cannot_access_admin_stats(self):
        self.client.force_authenticate(self.viewer)
        response = self.client.get(reverse('admin-stats'))
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
