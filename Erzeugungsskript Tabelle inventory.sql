USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[inventory]    Script Date: 10.10.2024 22:24:00 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[inventory](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[storage_location_id] [tinyint] NOT NULL,
	[product_id] [int] NOT NULL,
	[stock] [int] NOT NULL,
	[min_stock] [int] NOT NULL,
 CONSTRAINT [PK__inventor__3213E83FBBF5BBD2] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_inventory_product_location] UNIQUE NONCLUSTERED 
(
	[product_id] ASC,
	[storage_location_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[inventory] ADD  CONSTRAINT [DF_inventory_storage_location]  DEFAULT ((1)) FOR [storage_location_id]
GO

ALTER TABLE [dbo].[inventory] ADD  CONSTRAINT [DF__inventory__min_s__51300E55]  DEFAULT ((0)) FOR [min_stock]
GO

ALTER TABLE [dbo].[inventory]  WITH CHECK ADD  CONSTRAINT [FK_inventory_product] FOREIGN KEY([product_id])
REFERENCES [dbo].[products] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[inventory] CHECK CONSTRAINT [FK_inventory_product]
GO

ALTER TABLE [dbo].[inventory]  WITH CHECK ADD  CONSTRAINT [FK_inventory_storagelocation] FOREIGN KEY([storage_location_id])
REFERENCES [dbo].[inventory_storagelocations] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[inventory] CHECK CONSTRAINT [FK_inventory_storagelocation]
GO


