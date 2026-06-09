# -*- coding: utf-8 -*-
from datetime import timedelta
from django.test import TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from helpdesk.models import Queue, Ticket
from .helpers import get_staff_user


def _make_queue():
    return Queue.objects.create(title="Test Queue", slug="test_kanban")


def _ticket(queue, status, modified_weeks_ago):
    t = Ticket.objects.create(
        title="Test ticket",
        queue=queue,
        status=status,
        modified=timezone.now() - timedelta(weeks=modified_weeks_ago),
    )
    return t


@override_settings(HELPDESK_KANBAN_DEFAULT_RENDER_CLOSED_TICKETS_WEEKS=6)
class KanbanClosedTicketFilterTests(TestCase):
    def setUp(self):
        """
        Make a queue, user, login and
        grab the url
        """
        self.queue = _make_queue()
        self.user = get_staff_user()
        self.client.login(username=self.user.get_username(), password="password")
        self.url = reverse("helpdesk:kanban")

    def test_recent_closed_ticket_is_shown(self):
        """
        Tests HELPDESK_KANBAN_DEFAULT_RENDER_CLOSED_TICKETS_WEEKS
        Check if ticket modfied within 2 weeks does show
        as it should. (2 < 6)
        """
        t = _ticket(self.queue, Ticket.CLOSED_STATUS, modified_weeks_ago=2)
        response = self.client.get(self.url)
        self.assertContains(response, t.title)

    def test_stale_closed_ticket_is_hidden(self):
        """
        Tests HELPDESK_KANBAN_DEFAULT_RENDER_CLOSED_TICKETS_WEEKS
        Check if closed ticket modfied within 8 weeks doesnt show
        as it should. (8 > 6)
        """
        t = _ticket(self.queue, Ticket.CLOSED_STATUS, modified_weeks_ago=8)
        response = self.client.get(self.url)
        self.assertNotContains(response, t.title)

    def test_stale_duplicate_ticket_is_hidden(self):
        """
        Tests HELPDESK_KANBAN_DEFAULT_RENDER_CLOSED_TICKETS_WEEKS
        Check if duplicate ticket modfied within 8 weeks doesnt show
        as it should. (8 > 6)
        """
        t = _ticket(self.queue, Ticket.DUPLICATE_STATUS, modified_weeks_ago=8)
        response = self.client.get(self.url)
        self.assertNotContains(response, t.title)

    @override_settings(HELPDESK_KANBAN_DEFAULT_RENDER_CLOSED_TICKETS_WEEKS=0)
    def test_disabled_filter_shows_stale_closed_ticket(self):
        """
        Tests HELPDESK_KANBAN_DEFAULT_RENDER_CLOSED_TICKETS_WEEKS
        all ticket show when this settings is disabled.

        Setting up your server like this may cause issues with tons
        of tickets.
        """
        t = _ticket(self.queue, Ticket.CLOSED_STATUS, modified_weeks_ago=8)
        response = self.client.get(self.url)
        self.assertContains(response, t.title)
