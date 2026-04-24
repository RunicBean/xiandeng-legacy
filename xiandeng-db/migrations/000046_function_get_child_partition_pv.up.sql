
CREATE OR REPLACE FUNCTION get_child_partition_pv(p_accountid uuid, p_partition accountpartition)
RETURNS TABLE (
  account_id uuid,
  account_name TEXT,
  pv numeric(8,2),
  level TEXT,
  user_info TEXT,
  direct_child TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH cte AS (
    SELECT
      salesaccountid,
      SUM(amount) AS sum
    FROM
      partitionaward p
    WHERE
      accountid = p_accountid 
      AND partition = p_partition
    GROUP BY
      salesaccountid
  ),
  distinct_accounts AS (
    SELECT DISTINCT ON (a.account_id)
      a.account_id,
      a.account_name::TEXT AS account_name, -- Explicit cast to TEXT
      COALESCE(cte.sum, 0) AS pv,
      a.account_type,
      u.nickname,
      u.phone,
      u.email,
      CASE a.sub_level WHEN 1 THEN '是' ELSE '否' END AS direct_child 
    FROM
      get_accounts_by_partition_and_depth(
        p_accountid, 
        p_partition
      ) a
    LEFT JOIN cte ON a.account_id = cte.salesaccountid
    LEFT JOIN users u ON a.account_id = u.accountid
    ORDER BY a.account_id
  )
  SELECT 
    da.account_id AS account_id,
    da.account_name::text AS account_name,
    da.pv::numeric(8,2) AS pv,
    level.value::TEXT AS level,  -- Explicit cast to TEXT
    ('电话:' || COALESCE(da.phone, '无') || 
     ' 微信昵称:' || COALESCE(da.nickname, '无') || 
     ' 邮箱:' || COALESCE(da.email, '无'))::TEXT AS user_info,  -- Explicit cast to TEXT
    da.direct_child::text AS direct_child
  FROM 
    distinct_accounts da
  LEFT JOIN 
    datadictionary level ON da.account_type::text = level.key AND level.namespace = 'entitytype'
  ORDER BY 
    direct_child DESC, pv DESC;
END;
$$ LANGUAGE plpgsql;
