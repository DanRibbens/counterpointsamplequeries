declare @enddaytime datetime = @endday + ' 23:59:59'

select   
	coalesce(c.STR_ID, b.STR_ID, h.STR_ID) as STR_ID
        , coalesce(c.TKT_DT, b.DAT, h.DAT) as TKT_DT
        , coalesce(c.SALES, 0) as ACTUAL
        , coalesce(b.BUDGET, 0) as BUDGET
        , coalesce(c.SALES, 0) - coalesce(b.BUDGET, 0) as BUDGET_VARIANCE
	, coalesce(h.ACTUAL, 0) as LAST_YEAR
	, coalesce(c.SALES, 0) - coalesce(h.ACTUAL, 0) as VARIANCE
	, coalesce(c.SALES / h.ACTUAL, 0) as VARIANCE_PERCENT
from (
      SELECT   STR_ID
              , CAST(TKT_DT AS DATE) as TKT_DT
              , SUM(SUB_TOT) AS SALES
      FROM dbo.PS_TKT_HIST
      WHERE TKT_DT BETWEEN @startday AND @enddaytime and STR_ID between '200' and '217'
      GROUP BY STR_ID, CAST(TKT_DT AS DATE)
		)
		as c
		 full outer join ( 
    select SUM(p.SUB_TOT) AS ACTUAL
			, p.STR_ID
			, d.DAT
          FROM dbo.PS_TKT_HIST as p, dbo.DM_CAL_DAY as d
          WHERE p.TKT_DT between ( SELECT RETAIL_SAME_DAY_LST_YR FROM dbo.DM_CAL_DAY WHERE 	DAT = @startday ) and 
          ( SELECT RETAIL_SAME_DAY_LST_YR + ' 23:59:59' FROM dbo.DM_CAL_DAY WHERE DAT = @endday ) 
          and p.STR_ID between '200' and '217'
          and d.RETAIL_SAME_DAY_LST_YR = CAST(p.TKT_DT AS DATE)
          GROUP BY p.STR_ID, d.DAT
		) 
		as h
		on h.STR_ID = c.STR_ID and c.TKT_DT = h.DAT
		  full outer join ( 
      SELECT STR_ID, REVENUE_BUDGET as BUDGET
			, DAT
      FROM CK_BUDGET
      WHERE DAT between @startday and @endday
      and STR_ID between '200' and '217'
    ) 
    as b
	ON b.STR_ID = coalesce(c.STR_ID, h.STR_ID) and b.DAT = coalesce(c.TKT_DT, h.DAT)
	
	order by STR_ID, TKT_DT