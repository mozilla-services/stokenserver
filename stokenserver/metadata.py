from zope.interface import Interface, implements

from wimms.sql import SQLMetadata
from wimms.shardedsql import ShardedSQLMetadata


class IMetadataDB(Interface):

    def allocate_node(self, email, service):
        """Sets the node for the given email, service and node"""


class MetadataDB(SQLMetadata):
    implements(IMetadataDB)


class ShardedMetadataDB(ShardedSQLMetadata):
    implements(IMetadataDB)
