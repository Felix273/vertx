from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.content.models import ContentStatus, Episode, Genre, Series
from apps.users.models import ProducerProfile, User, UserRole


DEMO_PASSWORD = "DemoPass123!"
DEMO_PRODUCER_EMAIL = "producer@vertx.local"
DEMO_VIEWER_EMAIL = "viewer@vertx.local"
DEMO_ADMIN_EMAIL = "admin@vertx.local"


SERIES = [
    {
        "title": "Nairobi After Dark",
        "description": "Three friends chase one impossible night across Nairobi, where every turn reveals a new secret.",
        "genre": Genre.DRAMA,
        "is_free": True,
        "price": Decimal("0.00"),
        "thumbnail_url": "https://images.unsplash.com/photo-1618828665011-0abd973f7bb8?w=1200&q=85",
        "episodes": [
            ("The First Signal", "A mysterious voice note sends Amani across the city.", 420),
            ("City of Echoes", "The team follows a trail through the night markets.", 510),
            ("Before Sunrise", "One final choice changes everything.", 480),
        ],
    },
    {
        "title": "Mombasa Blue",
        "description": "A young marine biologist returns home and finds a family mystery beneath the Indian Ocean.",
        "genre": Genre.THRILLER,
        "is_free": False,
        "price": Decimal("199.00"),
        "thumbnail_url": "https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?w=1200&q=85",
        "episodes": [
            ("The Tide Turns", "Zuri discovers an impossible reading offshore.", 390),
            ("Deep Water", "A dive uncovers evidence someone wanted buried.", 450),
            ("The Return", "The truth reaches the shore.", 530),
        ],
    },
    {
        "title": "Letters from Kisumu",
        "description": "A warm, hopeful anthology about love, distance, and the messages that bring people home.",
        "genre": Genre.ROMANCE,
        "is_free": False,
        "price": Decimal("149.00"),
        "thumbnail_url": "https://images.unsplash.com/photo-1500534623283-312aade485b7?w=1200&q=85",
        "episodes": [
            ("The Blue Envelope", "A forgotten letter arrives ten years late.", 360),
            ("On the Platform", "Two strangers share a journey and a secret.", 405),
        ],
    },
]


class Command(BaseCommand):
    help = "Create or update deterministic VERTX demo accounts, published series, and episodes."

    def add_arguments(self, parser):
        parser.add_argument(
            "--password",
            default=DEMO_PASSWORD,
            help=f"Password for demo accounts (default: {DEMO_PASSWORD})",
        )
        parser.add_argument(
            "--reset",
            action="store_true",
            help="Delete only the seeded demo series before recreating them.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        password = options["password"]
        producer = self._get_producer(password)
        self._get_viewer(password)
        self._get_admin(password)

        if options["reset"]:
            Series.objects.filter(producer=producer, title__in=[s["title"] for s in SERIES]).delete()

        created_series = 0
        created_episodes = 0
        for payload in SERIES:
            episodes = payload["episodes"]
            series, created = Series.objects.update_or_create(
                producer=producer,
                title=payload["title"],
                defaults={
                    "description": payload["description"],
                    "genre": payload["genre"],
                    "thumbnail_url": payload["thumbnail_url"],
                    "trailer_url": "",
                    "is_free": payload["is_free"],
                    "price": payload["price"],
                    "status": ContentStatus.PUBLISHED,
                    "published_at": timezone.now(),
                },
            )
            created_series += int(created)

            for number, (title, description, duration) in enumerate(episodes, start=1):
                _, episode_created = Episode.objects.update_or_create(
                    series=series,
                    episode_number=number,
                    defaults={
                        "title": title,
                        "description": description,
                        "video_url": "https://storage.googleapis.com/coverr-main/mp4/Mt_Baker.mp4",
                        "video_id": f"demo-{series.pk}-{number}",
                        "duration_secs": duration,
                        "thumbnail_url": payload["thumbnail_url"],
                    },
                )
                created_episodes += int(episode_created)

        self.stdout.write(self.style.SUCCESS("VERTX demo data is ready."))
        self.stdout.write(f"  Series created: {created_series}; episodes created: {created_episodes}")
        self.stdout.write(f"  Producer: {DEMO_PRODUCER_EMAIL} / {password}")
        self.stdout.write(f"  Viewer:   {DEMO_VIEWER_EMAIL} / {password}")
        self.stdout.write(f"  Admin:    {DEMO_ADMIN_EMAIL} / {password}")
        self.stdout.write("  Free series: Nairobi After Dark")
        self.stdout.write("  Premium series: Mombasa Blue, Letters from Kisumu")

    def _get_producer(self, password):
        user, _ = User.objects.get_or_create(
            email=DEMO_PRODUCER_EMAIL,
            defaults={"full_name": "VERTX Demo Studio", "role": UserRole.PRODUCER},
        )
        user.role = UserRole.PRODUCER
        user.full_name = "VERTX Demo Studio"
        user.is_active = True
        user.set_password(password)
        user.save(update_fields=["role", "full_name", "is_active", "password"])
        ProducerProfile.objects.update_or_create(
            user=user,
            defaults={"studio_name": "VERTX Demo Studio", "bio": "Local demo producer"},
        )
        return user.producer_profile

    def _get_viewer(self, password):
        user, _ = User.objects.get_or_create(
            email=DEMO_VIEWER_EMAIL,
            defaults={"full_name": "Demo Viewer", "role": UserRole.VIEWER},
        )
        user.role = UserRole.VIEWER
        user.full_name = "Demo Viewer"
        user.is_active = True
        user.set_password(password)
        user.save(update_fields=["role", "full_name", "is_active", "password"])
        return user

    def _get_admin(self, password):
        user, _ = User.objects.get_or_create(
            email=DEMO_ADMIN_EMAIL,
            defaults={"full_name": "VERTX Demo Admin", "role": UserRole.ADMIN},
        )
        user.role = UserRole.ADMIN
        user.full_name = "VERTX Demo Admin"
        user.is_active = True
        user.is_staff = True
        user.is_superuser = True
        user.set_password(password)
        user.save(update_fields=["role", "full_name", "is_active", "is_staff", "is_superuser", "password"])
        return user
