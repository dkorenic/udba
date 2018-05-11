CREATE TABLE [dbo].[Logins]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_Logins_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_Logins_ServerName] DEFAULT (''),
[Persona] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LoginName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LoginSystemType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[LoginSID] [varchar] (172) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoginPasswordHash] [varchar] (514) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[LoginPasswordLastSetTimeUtc] [datetime2] (3) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[Output]
ON [dbo].[Logins]
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
	/*
    SELECT Deleted.DomainName
         , Deleted.ServerName
         , Deleted.Persona
         , Deleted.LoginName
         , Deleted.LoginSystemType
         , Deleted.LoginSID
         , Deleted.LoginPasswordHash
         , Deleted.IsActive
         --, $action
         , Inserted.DomainName
         , Inserted.ServerName
         , Inserted.Persona
         , Inserted.LoginName
         , Inserted.LoginSystemType
         , Inserted.LoginSID
         , Inserted.LoginPasswordHash
         , Inserted.IsActive
    FROM Deleted
        FULL OUTER JOIN Inserted
            ON Inserted.rowguid = Deleted.rowguid;
	*/
END;
GO
ALTER TABLE [dbo].[Logins] ADD CONSTRAINT [PK_Logins] PRIMARY KEY CLUSTERED  ([DomainName], [ServerName], [Persona], [LoginName]) ON [PRIMARY]
GO
