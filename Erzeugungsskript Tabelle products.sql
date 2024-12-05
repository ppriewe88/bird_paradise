USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[products]    Script Date: 10.10.2024 22:25:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[products](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [nvarchar](80) NOT NULL,
	[description] [nvarchar](max) NOT NULL,
	[category_id] [int] NOT NULL,
	[purchase_price] [decimal](10, 2) NOT NULL,
	[sale_price] [decimal](10, 2) NOT NULL,
	[supplier_id] [int] NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__products__3213E83FD71BE350] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[products] ADD  CONSTRAINT [DF_products_created_at]  DEFAULT (getdate()) FOR [created_at]
GO

ALTER TABLE [dbo].[products]  WITH CHECK ADD  CONSTRAINT [FK_products_category] FOREIGN KEY([category_id])
REFERENCES [dbo].[category] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[products] CHECK CONSTRAINT [FK_products_category]
GO

ALTER TABLE [dbo].[products]  WITH CHECK ADD  CONSTRAINT [FK_products_suppl] FOREIGN KEY([supplier_id])
REFERENCES [dbo].[suppliers] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[products] CHECK CONSTRAINT [FK_products_suppl]
GO

ALTER TABLE [dbo].[products]  WITH CHECK ADD  CONSTRAINT [CK_profitable_prices] CHECK  (([sale_price]>=[purchase_price]*(1.19)))
GO

ALTER TABLE [dbo].[products] CHECK CONSTRAINT [CK_profitable_prices]
GO


