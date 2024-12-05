USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[invoices_status]    Script Date: 10.10.2024 22:24:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[invoices_status](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__invoices__3213E83FCD4680A2] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[invoices_status] ADD  CONSTRAINT [DF_invoices_status_created_at]  DEFAULT (getdate()) FOR [created_at]
GO


