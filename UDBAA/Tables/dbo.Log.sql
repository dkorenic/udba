CREATE TABLE [dbo].[Log]
(
[InsertedAt] [datetime2] NOT NULL CONSTRAINT [DF_Log_InsertedAt] DEFAULT (getutcdate()),
[DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RecordRowGuid] [uniqueidentifier] NULL,
[StoredProcedure] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Operation] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Error] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[Log] ADD CONSTRAINT [PK_Log] PRIMARY KEY CLUSTERED  ([InsertedAt], [DomainName], [ServerName]) ON [PRIMARY]
GO
