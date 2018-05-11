CREATE TABLE [dbo].[Databases]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_Databases_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DatabaseName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DatabaseTypeCode] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Databases_DatabaseTypeCode] DEFAULT (''),
[Tennant] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Databases_Tennant] DEFAULT ('')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Databases] ADD CONSTRAINT [PK_Databases] PRIMARY KEY CLUSTERED  ([DatabaseName], [ServerName], [DomainName]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Databases] ADD CONSTRAINT [FK_Databases_DatabaseTypes] FOREIGN KEY ([DatabaseTypeCode]) REFERENCES [dbo].[DatabaseTypes] ([Code]) ON UPDATE CASCADE
GO
