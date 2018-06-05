CREATE TABLE [remote].[ServerRoles]
(
[RemoteDomainName] [nvarchar] (64) NOT NULL,
[RemoteServerName] [nvarchar] (64) NOT NULL,
[RowId] [uniqueidentifier] NOT NULL,
[DomainName] [nvarchar] (64) NOT NULL,
[RoleName] [nvarchar] (64) NOT NULL,
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [remote].[ServerRoles] ADD CONSTRAINT [PK_ServerRoles] PRIMARY KEY CLUSTERED  ([RemoteDomainName], [RemoteServerName], [RoleName], [DomainName]) ON [PRIMARY]
GO
