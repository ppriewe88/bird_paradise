USE [ProjektarbeitPP]
GO

/****** Object:  Table [dbo].[users]    Script Date: 10.10.2024 22:26:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[users](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[username] [nvarchar](80) NOT NULL,
	[customer_id] [int] NULL,
	[supplier_id] [int] NULL,
	[employee_id] [int] NULL,
	[email] [nvarchar](80) NOT NULL,
	[password] [nvarchar](50) NOT NULL,
	[created_at] [datetime] NOT NULL,
 CONSTRAINT [PK__users__3213E83FCF1ACAA0] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_user_uniqueFK] UNIQUE NONCLUSTERED 
(
	[customer_id] ASC,
	[supplier_id] ASC,
	[employee_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[users] ADD  CONSTRAINT [DF_users_created_at]  DEFAULT (getdate()) FOR [created_at]
GO

ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [FK_user_cust] FOREIGN KEY([customer_id])
REFERENCES [dbo].[customers] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[users] CHECK CONSTRAINT [FK_user_cust]
GO

ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [FK_user_emp] FOREIGN KEY([employee_id])
REFERENCES [dbo].[employees] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[users] CHECK CONSTRAINT [FK_user_emp]
GO

ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [FK_user_suppl] FOREIGN KEY([supplier_id])
REFERENCES [dbo].[suppliers] ([id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[users] CHECK CONSTRAINT [FK_user_suppl]
GO

ALTER TABLE [dbo].[users]  WITH CHECK ADD  CONSTRAINT [CK_user_exactlyoneFK] CHECK  (([customer_id] IS NOT NULL AND [supplier_id] IS NULL AND [employee_id] IS NULL OR [customer_id] IS NULL AND [supplier_id] IS NOT NULL AND [employee_id] IS NULL OR [customer_id] IS NULL AND [supplier_id] IS NULL AND [employee_id] IS NOT NULL))
GO

ALTER TABLE [dbo].[users] CHECK CONSTRAINT [CK_user_exactlyoneFK]
GO


