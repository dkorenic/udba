CREATE TABLE [dbo].[ServerRoles]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_ServerRoles_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ServerRoles_DomainName] DEFAULT (''),
[RoleName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ServerRoles] ADD CONSTRAINT [PK_ServerRoles] PRIMARY KEY CLUSTERED  ([RoleName], [DomainName]) ON [PRIMARY]
GO
