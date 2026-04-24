 CREATE TABLE studenttags (
    studentid UUID,
    tag VARCHAR(255),
    PRIMARY KEY (studentid, tag)
);

CREATE or replace VIEW public.v_users AS
SELECT 
    u.*, 
    CASE
        WHEN EXISTS (SELECT 1 FROM guardian g WHERE g.guardianid = u.id) THEN 'guardian'
        WHEN (SELECT type FROM account WHERE id = u.accountid LIMIT 1) = 'STUDENT' THEN 'student'
        ELSE 'agent'
    END AS usertype
FROM 
    public.users u;

create or replace view public.v_studentdetails as 
SELECT DISTINCT ON (s.id) s.id AS studentid,
       s.upstreamaccount AS agentid,
       s.accountname AS studentname,
       s.createdat,
       suser.phone AS studentphone,
       suser.nickname AS studentwechatname,
       suser.email AS studentemail,
       guser.phone AS guardianphone,
       guser.nickname AS guardianwechatname,
       guser.email AS guardianemail,
       g.relationship,
       (SELECT array_agg(productname) AS purchasedproduct
        FROM (
            SELECT productname
            FROM product
            WHERE id IN (
                SELECT DISTINCT productid
                FROM orderproduct op
                WHERE op.orderid IN (
                    SELECT id
                    FROM orders o
                    WHERE o.status = 'success' AND o.studentid = s.id
                )
            ) 
            ORDER BY 1
        ) p),
       (SELECT array_agg(tag) AS tags
        FROM (
            SELECT tag
            FROM studenttags
            WHERE studentid = s.id
            ORDER BY 1
        ) t)
FROM account s
LEFT JOIN v_users suser ON suser.accountid = s.id AND suser.usertype = 'student'
LEFT JOIN v_users guser ON guser.accountid = s.id AND guser.usertype = 'guardian'
LEFT JOIN guardian g ON g.guardianid = guser.id
WHERE s.type = 'STUDENT'
ORDER BY s.id, s.createdat DESC;
