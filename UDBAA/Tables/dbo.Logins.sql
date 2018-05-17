CREATE TABLE [dbo].[Logins]
(
[RowId] [uniqueidentifier] NOT NULL ROWGUIDCOL CONSTRAINT [DF_Logins_RowId] DEFAULT (newid()),
[DomainName] [nvarchar] (64) NOT NULL,
[ServerName] [nvarchar] (64) NOT NULL CONSTRAINT [DF_Logins_ServerName] DEFAULT (''),
[Persona] [nvarchar] (64) NOT NULL,
[LoginName] [nvarchar] (128) NOT NULL,
[LoginSystemType] [char] (1) NOT NULL,
[LoginSID] [varchar] (172) NULL,
[LoginPasswordHash] [varchar] (514) NULL,
[IsActive] [bit] NULL,
[LoginPasswordLastSetTimeUtc] [datetime2] (3) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[Logins_Deleted]
ON [dbo].[Logins]
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT deleted.Logins
    (
        RowId
    )
    SELECT d.RowId
    FROM Deleted                 AS d
        LEFT JOIN deleted.Logins AS dd
            ON d.RowId = dd.RowId
    WHERE dd.RowId IS NULL;

END;

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[Logins_Log]
ON [dbo].[Logins]
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ctx nvarchar(128) = CONTEXT_INFO();

    INSERT INTO log.Logins
    (
        ContextInfo
      , D_RowId
      , D_DomainName
      , D_ServerName
      , D_Persona
      , D_LoginName
      , D_LoginSystemType
      , D_LoginSID
      , D_LoginPasswordHash
      , D_IsActive
      , D_LoginPasswordLastSetTimeUtc
      , I_RowId
      , I_DomainName
      , I_ServerName
      , I_Persona
      , I_LoginName
      , I_LoginSystemType
      , I_LoginSID
      , I_LoginPasswordHash
      , I_IsActive
      , I_LoginPasswordLastSetTimeUtc
    )
    SELECT @ctx
         , Deleted.RowId
         , Deleted.DomainName
         , Deleted.ServerName
         , Deleted.Persona
         , Deleted.LoginName
         , Deleted.LoginSystemType
         , Deleted.LoginSID
         , Deleted.LoginPasswordHash
         , Deleted.IsActive
         , Deleted.LoginPasswordLastSetTimeUtc
         --
         , Inserted.RowId
         , Inserted.DomainName
         , Inserted.ServerName
         , Inserted.Persona
         , Inserted.LoginName
         , Inserted.LoginSystemType
         , Inserted.LoginSID
         , Inserted.LoginPasswordHash
         , Inserted.IsActive
         , Inserted.LoginPasswordLastSetTimeUtc
    FROM Deleted
        FULL OUTER JOIN Inserted
            ON Inserted.ROWGUIDCOL = Deleted.ROWGUIDCOL;

END;

GO
ALTER TABLE [dbo].[Logins] ADD CONSTRAINT [PK_Logins] PRIMARY KEY CLUSTERED  ([DomainName], [ServerName], [Persona], [LoginName]) ON [PRIMARY]
GO
