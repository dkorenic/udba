CREATE TABLE [dbo].[DatabaseUsers]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_DatabaseUsers_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_DatabaseUsers_DomainName] DEFAULT (''),
[ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_DatabaseUsers_ServerName] DEFAULT (''),
[Tennant] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_DatabaseUsers_Tennant] DEFAULT (''),
[DatabaseTypeCode] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_DatabaseUsers_DatabaseTypeCode] DEFAULT (''),
[DatabaseName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_DatabaseUsers_DatabaseName] DEFAULT (''),
[Persona] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsActive] [bit] NULL CONSTRAINT [DF_IsActive] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DatabaseUsers] ADD CONSTRAINT [PK_DatabaseUsers] PRIMARY KEY CLUSTERED  ([DomainName], [ServerName], [Tennant], [DatabaseTypeCode], [DatabaseName], [Persona]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DatabaseUsers] ADD CONSTRAINT [FK_DatabaseUsers_DatabaseTypes] FOREIGN KEY ([DatabaseTypeCode]) REFERENCES [dbo].[DatabaseTypes] ([Code]) ON UPDATE CASCADE
GO
