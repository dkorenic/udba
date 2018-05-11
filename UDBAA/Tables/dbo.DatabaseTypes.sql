CREATE TABLE [dbo].[DatabaseTypes]
(
[Code] [nvarchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DatabaseTypeName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DefaultSuffix] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DatabaseTypes] ADD CONSTRAINT [PK_DatabaseTypes] PRIMARY KEY CLUSTERED  ([Code]) ON [PRIMARY]
GO
