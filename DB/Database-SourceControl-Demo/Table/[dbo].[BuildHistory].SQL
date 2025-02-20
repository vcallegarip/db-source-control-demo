DROP TABLE IF EXISTS [dbo].[BuildHistory]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BuildHistory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BuildVersion] [varchar](10) NULL,
	[BuildLog] [nvarchar](max) NULL,
	[UpdatedDate] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[BuildHistory] ADD  DEFAULT (getutcdate()) FOR [UpdatedDate]
GO
