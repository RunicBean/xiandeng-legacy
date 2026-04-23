-- name: GetUser :one
SELECT 
NickName,
Password
FROM User
WHERE Id = ? LIMIT 1;

-- name: ListUsers :many
SELECT 
BIN_TO_UUID(ID) AS ID,
NickName
FROM User;

-- name: InitCreateUser :execresult
INSERT INTO User (
  Id,
  Phone,
  Password,
  NickName,
  WechatOpenId,
  AvatarURL,
  Source
) VALUES (
  UUID_TO_BIN(?), ?, ?, ?, ?, ?, ?
);

-- name: CreateUserWithPassword :execresult
-- INSERT INTO User (
--     Password
-- ) VALUES (
--     ?, ?
-- );

-- name: UpdateUserPassword :exec
UPDATE User 
SET Password = ?
WHERE ID = ?;

-- name: UpdateUserProfile :exec
UPDATE User
SET 
NickName = ?,
Email = ?,
Phone = ?
WHERE ID = ?;

-- name: DeleteUser :exec
DELETE FROM User
WHERE Id = ?;


-- name: CreateAccount :execresult
INSERT INTO Account (
  Id,
  Type
) VALUES (
  UUID_TO_BIN(?), ?
);


-- name: ListRoles :many
SELECT * FROM Role
ORDER BY CreatedAt DESC;

-- name: CreateRole :execresult
INSERT INTO Role (
    Name
) VALUES (
    ?
);

-- name: DeleteRole :exec
DELETE FROM Role
WHERE Id = ?;

-- name: DeleteRoleByName :exec
DELETE FROM Role
WHERE Name = ?;