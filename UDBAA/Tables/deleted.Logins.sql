CREATE TABLE [deleted].[Logins]
(
[Id] [bigint] NOT NULL IDENTITY(1, 1),
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL,
[DeletedAtUtc] [datetime2] (3) NULL CONSTRAINT [DF_DeletedAtUtc] DEFAULT (getutcdate())
) ON [PRIMARY]
GO
ALTER TABLE [deleted].[Logins] ADD CONSTRAINT [PK_Logins] PRIMARY KEY NONCLUSTERED  ([RowId]) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CI_Logins] ON [deleted].[Logins] ([Id]) ON [PRIMARY]
GO
