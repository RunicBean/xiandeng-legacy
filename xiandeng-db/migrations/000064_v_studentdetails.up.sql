 
CREATE OR REPLACE VIEW public.v_studentdetails
AS SELECT 
    a.id AS studentid,
    a.upstreamaccount AS agentid,
    a.accountname AS studentname,
    a.createdat,
    suser.phone AS studentphone,
    suser.nickname AS studentwechatname,
    suser.email AS studentemail,
    guser.phone AS guardianphone,
    guser.nickname AS guardianwechatname,
    guser.email AS guardianemail,
    g.relationship,
    p.purchasedproduct,
    stags.tags
FROM account a
LEFT JOIN useraccountrole uar_student ON uar_student.accountid = a.id 
    AND uar_student.roleid = (SELECT id FROM roles WHERE accountkind='STUDENT' AND rolename='STUDENT')
LEFT JOIN users suser ON suser.id = uar_student.userid
LEFT JOIN useraccountrole uar_guardian ON uar_guardian.accountid = a.id 
    AND uar_guardian.roleid = (SELECT id FROM roles WHERE accountkind='STUDENT' AND rolename='GUARDIAN_PRIMARY')
LEFT JOIN users guser ON guser.id = uar_guardian.userid
LEFT JOIN guardian g ON g.guardianid = guser.id
LEFT JOIN (
    SELECT o.studentid, array_agg(DISTINCT pr.productname) AS purchasedproduct
    FROM orders o
    JOIN orderproduct op ON op.orderid = o.id
    JOIN product pr ON pr.id = op.productid
    WHERE o.status IN ('paid', 'settled')
    GROUP BY o.studentid
) p ON p.studentid = a.id
LEFT JOIN (
    SELECT studentid, array_agg(tag) AS tags
    FROM studenttags
    GROUP BY studentid
) stags ON stags.studentid = a.id
WHERE a.type = 'STUDENT'::entitytype
