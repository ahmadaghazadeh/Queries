INSERT INTO dbo.CustomerPoint (
	RunDate,
	CustomerID,
	latitude,
	longitude,
	accuracy,
	googleAddress,
	DATE,
	ModifyDate,
	UserID,
	IsDeleted
) SELECT
	dbo.fn_GetPersianDateTime (GETDATE()),
	dbo.fn_GetPersonID (c.moshkey),
	c.latitude,
	c.longitude,
	c.accuracy,
	c.googleAddress,
	c. DATE,
	GETDATE(),
	4,
	0
FROM
	sale_Tabriz_1395.dbo.CustomerPoints c
WHERE
	id = (
		SELECT
			MAX (id)
		FROM
			sale_Tabriz_1395.dbo.CustomerPoints c1
		WHERE
			c1.moshkey = c.moshkey
	)