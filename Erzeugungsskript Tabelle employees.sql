USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[employees]    Script Date: 10.10.2024 22:23:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[employees](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[email] [nvarchar](80) NOT NULL,
	[phone] [bigint] NULL,
	[city] [nvarchar](50) NULL,
	[address] [nvarchar](80) NULL,
	[country] [nvarchar](50) NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__employee__3213E83F8A5E8C20] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[employees] ADD  CONSTRAINT [DF_employees_created_at]  DEFAULT (getdate()) FOR [created_at]
GO


