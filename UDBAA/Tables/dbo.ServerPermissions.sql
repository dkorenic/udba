CREATE TABLE [dbo].[ServerPermissions]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_ServerPermissions_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) NOT NULL CONSTRAINT [DF_ServerPermissions_DomainName] DEFAULT (''),
[ServerName] [nvarchar] (64) NOT NULL CONSTRAINT [DF_ServerPermissions_ServerName] DEFAULT (''),
[Persona] [nvarchar] (64) NOT NULL,
[Permission] [nvarchar] (64) NOT NULL,
[Target] [nvarchar] (64) NOT NULL CONSTRAINT [DF_ServerPermissions_Target] DEFAULT (''),
[State] [char] (1) NOT NULL CONSTRAINT [DF_ServerPermissions_State] DEFAULT ('G'),
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ServerPermissions] ADD CONSTRAINT [PK_ServerPermissions_1] PRIMARY KEY CLUSTERED  ([DomainName], [ServerName], [Persona], [Permission], [Target]) ON [PRIMARY]
GO
