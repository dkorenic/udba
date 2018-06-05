CREATE TABLE [remote].[ServerRoleMembers]
(
[RemoteDomainName] [nvarchar] (64) NOT NULL,
[RemoteServerName] [nvarchar] (64) NOT NULL,
[RowId] [uniqueidentifier] NOT NULL,
[DomainName] [nvarchar] (64) NOT NULL,
[ServerName] [nvarchar] (64) NOT NULL,
[RoleName] [nvarchar] (64) NOT NULL,
[Persona] [nvarchar] (64) NOT NULL,
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [remote].[ServerRoleMembers] ADD CONSTRAINT [PK_ServerRoleMembers] PRIMARY KEY CLUSTERED  ([RemoteDomainName], [RemoteServerName], [DomainName], [ServerName], [RoleName], [Persona]) ON [PRIMARY]
GO
