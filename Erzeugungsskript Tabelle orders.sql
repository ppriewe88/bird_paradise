USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[orders]    Script Date: 10.10.2024 22:25:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[orders](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[customer_id] [int] NOT NULL,
	[product_id] [int] NOT NULL,
	[quantity] [bigint] NOT NULL,
	[status_id] [int] NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__orders__3213E83F99C761F0] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[orders] ADD  CONSTRAINT [DF_orders_status_id]  DEFAULT ((1)) FOR [status_id]
GO

ALTER TABLE [dbo].[orders] ADD  CONSTRAINT [DF_orders_created_at]  DEFAULT (getdate()) FOR [created_at]
GO

ALTER TABLE [dbo].[orders]  WITH CHECK ADD  CONSTRAINT [FK_orders_customer] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [FK_orders_customer]
GO

ALTER TABLE [dbo].[orders]  WITH CHECK ADD  CONSTRAINT [FK_orders_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[products] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [FK_orders_product]
GO

ALTER TABLE [dbo].[orders]  WITH CHECK ADD  CONSTRAINT [FK_orders_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[orders_status] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[orders] CHECK CONSTRAINT [FK_orders_status]
GO


