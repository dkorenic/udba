CREATE TABLE [log].[Logins]
(
[Id] [bigint] NOT NULL IDENTITY(1, 1),
[HappenedAtUtc] [datetime2] (3) NOT NULL CONSTRAINT [DF_HappenedAt] DEFAULT (getutcdate()),
[ContextInfo] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_RowId] [uniqueidentifier] NULL,
[I_RowId] [uniqueidentifier] NULL,
[D_DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[I_DomainName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[I_ServerName] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_Persona] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[I_Persona] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_LoginName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[I_LoginName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_LoginSystemType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[I_LoginSystemType] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_LoginSID] [varchar] (172) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[I_LoginSID] [varchar] (172) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_LoginPasswordHash] [varchar] (514) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[I_LoginPasswordHash] [varchar] (514) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[D_IsActive] [bit] NULL,
[I_IsActive] [bit] NULL,
[D_LoginPasswordLastSetTimeUtc] [datetime2] (3) NULL,
[I_LoginPasswordLastSetTimeUtc] [datetime2] (3) NULL
) ON [PRIMARY]
GO
ALTER TABLE [log].[Logins] ADD CONSTRAINT [PK_Logins] PRIMARY KEY CLUSTERED  ([Id]) ON [PRIMARY]
GO
