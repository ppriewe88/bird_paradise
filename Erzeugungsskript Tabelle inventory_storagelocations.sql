USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[inventory_storagelocations]    Script Date: 10.10.2024 22:24:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[inventory_storagelocations](
	[id] [tinyint] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__inventor__3213E83F185CE139] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[inventory_storagelocations] ADD  CONSTRAINT [DF_inventory_storagelocations_created_at]  DEFAULT (getdate()) FOR [created_at]
GO


