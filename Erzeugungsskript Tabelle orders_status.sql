USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[orders_status]    Script Date: 10.10.2024 22:25:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[orders_status](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__orders_s__3213E83F5EB3FE29] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[orders_status] ADD  CONSTRAINT [DF_orders_status_created_at]  DEFAULT (getdate()) FOR [created_at]
GO


