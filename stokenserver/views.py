# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
import json
from cornice import Service
from stokenserver.metadata import IMetadataDB


metadata = Service(name='metadata', path='/1.0/{service}')


def get_email(request):
    try:
        data = json.loads(request.body)
    except ValueError:
        request.errors.add('body', 'json', 'invalid json')
        return

    if 'email' not in data:
        request.errors.add('body', 'email', 'missing field')
    else:
        request.validated['email'] = data['email']

    request.validated['service'] = request.matchdict['service']


@metadata.post(validator=get_email)
def allocate_node(request):
    metadata_db = request.registry.queryUtility(IMetadataDB)
    uid, node = metadata_db.allocate_node(request.validated['email'],
                                          request.validated['service'])
    return {'node': node, 'uid': uid}
