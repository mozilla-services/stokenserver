# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
import os
import unittest
import json
from pyramid import testing
from webtest import TestApp
from stokenserver.metadata import IMetadataDB

from mozsvc.config import load_into_settings
from cornice.tests import CatchErrors


class TestFixedBackend(unittest.TestCase):

    def setUp(self):
        self.config = testing.setUp()
        self.ini = os.path.join(os.path.dirname(__file__),
                                'test_fixednode.ini')
        settings = {}
        load_into_settings(self.ini, settings)
        self.config.add_settings(settings)
        self.config.include("stokenserver")
        self.backend = self.config.registry.getUtility(IMetadataDB)

        # adding a node with 100 slots
        self.backend._safe_execute(
              """insert into nodes (`node`, `service`, `available`,
                    `capacity`, `current_load`, `downed`, `backoff`)
                  values ("phx12", "sync", 100, 100, 0, 0, 0)""")

        self._sqlite = self.backend._engine.driver == 'pysqlite'
        wsgiapp = self.config.make_wsgi_app()
        wsgiapp = CatchErrors(wsgiapp)
        self.app = TestApp(wsgiapp)

    def tearDown(self):
        if self._sqlite:
            filename = self.backend.sqluri.split('sqlite://')[-1]
            if os.path.exists(filename):
                os.remove(filename)
        else:
            self.backend._safe_execute('delete from nodes')
            self.backend._safe_execute('delete from user_nodes')

    def test_read_config(self):
        user, service = 'tarek@mozilla.com', 'sync'
        if self._sqlite:
            wanted = (1, u'phx12', None)
        else:
            wanted = (0, u'phx12', None)

        self.assertEqual(wanted[:-1], self.backend.allocate_node(user, service))
        self.assertEqual(wanted, self.backend.get_node(user, service))

    def test_api(self):

        data = {'email': 'tarek@mozilla.com'}
        res = self.app.post('/1.0/sync', json.dumps(data))
        res = res.json
        self.assertEqual(res['node'], 'phx12')
        if self._sqlite:
            wanted_uid = 1
        else:
            wanted_uid = 0

        self.assertEqual(res['uid'], wanted_uid)
