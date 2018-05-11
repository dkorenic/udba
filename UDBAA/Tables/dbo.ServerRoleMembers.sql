CREATE TABLE [dbo].[ServerRoleMembers]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_ServerRoleMembers_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ServerRoleMembers_DomainName] DEFAULT (''),
[ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ServerRoleMembers_ServerName] DEFAULT (''),
[RoleName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Persona] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsActive] [bit] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ServerRoleMembers] ADD CONSTRAINT [PK_ServerRoleMembers] PRIMARY KEY CLUSTERED  ([DomainName], [ServerName], [RoleName], [Persona]) ON [PRIMARY]
GO
