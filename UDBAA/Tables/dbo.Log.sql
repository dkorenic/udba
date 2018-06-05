CREATE TABLE [dbo].[Log]
(
[InsertedAt] [datetime2] NOT NULL CONSTRAINT [DF_Log_InsertedAt] DEFAULT (getutcdate()),
[DomainName] [nvarchar] (64) NOT NULL,
[ServerName] [nvarchar] (64) NOT NULL,
[RowGuid] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_Log_RowGuid] DEFAULT (newid()),
[RecordRowGuid] [uniqueidentifier] NULL,
[StoredProcedure] [nvarchar] (max) NULL,
[Operation] [nvarchar] (max) NULL,
[Description] [nvarchar] (max) NULL,
[Error] [nvarchar] (max) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Log] ADD CONSTRAINT [PK_Log_1] PRIMARY KEY CLUSTERED  ([InsertedAt], [DomainName], [ServerName], [RowGuid]) ON [PRIMARY]
GO
