CREATE TABLE `Account` (
  `Id` binary(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
  `Type` ENUM ('Head Quarter', 'Lv1 Agent', 'Lv2 Agent', 'Student'),
  `Coins` float COMMENT '通线下充值获得的虚拟金币',
  `Balance` float COMMENT '通真实充值获得的余额',
  `UpstreamAccount` binary(16),
  `AccountName` varchar(255) COMMENT '公司名需手动输入，学生名为FirstName+LastName',
  `CreatedAt` timestamp DEFAULT (CURRENT_TIMESTAMP),
  `UpdatedAt` timestamp DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE User (
    `Id` binary(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    `Password` varchar(5096) NOT NULL,
    `Phone` varchar(255) UNIQUE NOT NULL,
    `Email` varchar(255) UNIQUE,
    `NickName` varchar(255) NOT NULL COMMENT '可从微信授权中获取',
    `FirstName` varchar(255),
    `LastName` varchar(255),
    `WechatOpenId` varchar(255) UNIQUE COMMENT '微信授权登录的openId,对于学生和家长是必填',
    `Sex` tinyint NOT NULL DEFAULT 0 COMMENT '可从微信授权中获取，默认0。值为1时是男性，值为2时是女性',
    `Province` varchar(255) COMMENT '可从微信授权中获取',
    `City` varchar(255) COMMENT '可从微信授权中获取',
    `BirthDate` date,
    `AvatarURL` varchar(5096) COMMENT '可从微信授权中获取',
    `Source` ENUM ("QRCode", "PlainLink") COMMENT '用户注册来源，Scan QR, etc',
    `AccountId` binary(16),
    `CreatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `UpdatedAt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT AcctID_FK FOREIGN KEY (AccountId) REFERENCES `Account`(ID)
);

CREATE TABLE `StudentAttribute` (
  `AccountId` binary(16) PRIMARY KEY,
  `University` varchar(255),
  `Faculty` varchar(255),
  `Department` varchar(255),
  `Major` varchar(255),
  `CreatedAt` timestamp DEFAULT (CURRENT_TIMESTAMP),
  `UpdatedAt` timestamp DEFAULT (CURRENT_TIMESTAMP) ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE `Privilege` (
  `Id` binary(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())) COMMENT 'UUID',
  `AccountType` ENUM ('Head Quarter', 'Lv1 Agent', 'Lv2 Agent', 'Student'),
  `Name` varchar(255)
);

CREATE TABLE Role (
    ID binary(16) PRIMARY KEY DEFAULT (UUID_TO_BIN(UUID())),
    Name varchar(60) NOT NULL,
    CreatedAt timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

Create TABLE CasbinRule (
    p_type varchar(32) NOT NULL,
    v0 binary(16) NOT NULL,
    v1 binary(16) NOT NULL,
    v2 varchar(255) NOT NULL,
    v3 varchar(255) NOT NULL,
    v4 varchar(255) NOT NULL,
    v5 varchar(255) NOT NULL
);

CREATE TABLE Entitlement (
    ID bigint PRIMARY KEY DEFAULT (UUID_SHORT()),
    IsValid boolean DEFAULT 0,
    IsDraft boolean,
    IsDeleted boolean DEFAULT 0,
    StudentID varchar(64),
    DraftID varchar(64),
    IsSurveyCompleted boolean,
    LV1AgentID varchar(64),
    LV1Permitted boolean,
    LV1Memo text,
    LV2AgentID varchar(64),
    LV2Permitted boolean,
    LV2Memo text, 
    Price float,
    Memo text,
    QRCodeUrl varchar(256),
    CreatedAt timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);