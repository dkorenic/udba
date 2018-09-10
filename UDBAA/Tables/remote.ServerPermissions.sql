CREATE TABLE [remote].[ServerPermissions]
(
[RemoteDomainName] [nvarchar] (64) NOT NULL,
[RemoteServerName] [nvarchar] (64) NOT NULL,
[RowId] [uniqueidentifier] NOT NULL,
[DomainName] [nvarchar] (64) NOT NULL,
[ServerName] [nvarchar] (64) NOT NULL,
[Persona] [nvarchar] (64) NOT NULL,
[Permission] [nvarchar] (64) NOT NULL,
[Target] [nvarchar] (64) NOT NULL,
[State] [char] (1) NOT NULL,
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [remote].[ServerPermissions] ADD CONSTRAINT [PK_ServerPermissions] PRIMARY KEY CLUSTERED  ([RemoteDomainName], [RemoteServerName], [DomainName], [ServerName], [Persona], [State], [Permission], [Target]) ON [PRIMARY]
GO
