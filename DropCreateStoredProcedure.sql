USE [MyCatalog]
GO

IF EXISTS (SELECT * FROM sysobjects WHERE type = 'P' AND name = '[MyStoredProcedure]')
	BEGIN
		DROP PROCEDURE [MyStoredProcedure]
	END

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:
-- Create date: 
-- Description:	
-- =============================================

ALTER PROCEDURE [dbo].[MyStoredProcedure]
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Do something interesting
	
END