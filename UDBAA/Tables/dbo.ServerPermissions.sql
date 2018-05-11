CREATE TABLE [dbo].[ServerPermissions]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_ServerPermissions_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ServerPermissions_DomainName] DEFAULT (''),
[ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ServerPermissions_ServerName] DEFAULT (''),
[Persona] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Permission] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ServerPermissions] ADD CONSTRAINT [PK_ServerPermissions] PRIMARY KEY CLUSTERED  ([DomainName], [ServerName], [Persona], [Permission]) ON [PRIMARY]
GO
