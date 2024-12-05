USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[invoices]    Script Date: 10.10.2024 22:24:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[invoices](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[order_id] [int] NOT NULL,
	[total_price] [decimal](10, 2) NOT NULL,
	[total_discount] [decimal](10, 2) NOT NULL,
	[total_price_discounted] [decimal](10, 2) NOT NULL,
	[due_limit] [int] NULL,
	[due_date]  AS (dateadd(day,[due_limit],[created_at])) PERSISTED,
	[overdue_fee] [decimal](10, 2) NULL,
	[status_id] [int] NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__invoices__3213E83FBC9E069A] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_invoice_orderID] UNIQUE NONCLUSTERED 
(
	[order_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[invoices] ADD  CONSTRAINT [DF_invoices_due_limit]  DEFAULT ((30)) FOR [due_limit]
GO

ALTER TABLE [dbo].[invoices] ADD  CONSTRAINT [DF_invoices_overdue_fee]  DEFAULT ((0)) FOR [overdue_fee]
GO

ALTER TABLE [dbo].[invoices] ADD  CONSTRAINT [DF_invoices_created_at]  DEFAULT (getdate()) FOR [created_at]
GO

ALTER TABLE [dbo].[invoices]  WITH CHECK ADD  CONSTRAINT [FK_invoices_orders] FOREIGN KEY([order_id])
REFERENCES [dbo].[orders] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[invoices] CHECK CONSTRAINT [FK_invoices_orders]
GO

ALTER TABLE [dbo].[invoices]  WITH CHECK ADD  CONSTRAINT [FK_invoices_status] FOREIGN KEY([status_id])
REFERENCES [dbo].[invoices_status] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[invoices] CHECK CONSTRAINT [FK_invoices_status]
GO


