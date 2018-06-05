CREATE TABLE [tmp].[dbo.Logins]
(
[RowId] [uniqueidentifier] NOT NULL,
[DomainName] [nvarchar] (64) NOT NULL,
[ServerName] [nvarchar] (64) NOT NULL,
[Persona] [nvarchar] (64) NOT NULL,
[LoginName] [nvarchar] (128) NOT NULL,
[LoginSystemType] [char] (1) NOT NULL,
[LoginSID] [varchar] (172) NULL,
[LoginPasswordHash] [varchar] (514) NULL,
[IsActive] [bit] NULL,
[LoginPasswordLastSetTimeUtc] [datetime2] (3) NULL
) ON [PRIMARY]
GO
