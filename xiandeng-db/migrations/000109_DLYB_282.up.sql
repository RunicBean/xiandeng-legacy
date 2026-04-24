
-- 创建学习清单表
CREATE TABLE study_checklist (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    semester CHAR(2) NOT NULL,
    category VARCHAR(15) NOT NULL,
    title VARCHAR(255) NOT NULL
);

-- 创建学生学习清单状态表
CREATE TABLE student_study_checklist_status (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES account(id),
    student_checklist_id UUID NOT NULL REFERENCES study_checklist(id),
    is_complete BOOLEAN NOT NULL DEFAULT false
);

-- 创建索引
CREATE INDEX idx_student_study_checklist_status_student_id ON student_study_checklist_status(student_id);
CREATE INDEX idx_student_study_checklist_status_checklist_id ON student_study_checklist_status(student_checklist_id);

ALTER TABLE study_checklist ADD COLUMN tags TEXT[];
ALTER TABLE study_checklist ADD COLUMN created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT null;
ALTER TABLE  student_study_checklist_status ADD COLUMN created_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT null;
ALTER TABLE  student_study_checklist_status ADD COLUMN updated_at timestamp DEFAULT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Shanghai'::text) NOT null;

create trigger trg_student_study_checklist_status_auto_updated before
update
    on
    public.accountusertaskdata for each row execute function update_updated_at_column();

insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','学习类','1. 准备英语分班考，提前学习大学英语核心词汇和语法',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','学习类','2. 提前学习高等数学基础内容（函数、极限、导数）',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','学习类','3. 了解专业基础课程，阅读1-2本专业入门书籍',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','技能类','1. 报名计算机二级考试，开始基础学习（Excel、Word高级功能）',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','技能类','2. 报名驾驶证考试，完成科目一和部分实操训练',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','技能类','3. 学习基础PPT制作技巧，掌握演示文稿设计要点',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','规划类','1. 了解大学培养方案和毕业要求',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','规划类','2. 收集目标大学的社团、学生会信息，确定1-2个感兴趣方向',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','规划类','3. 制定大学第一年的初步规划和目标',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','生活类','1. 调整作息时间，适应大学学习节奏',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','生活类','2. 学习独立生活技能（如简单烹饪、衣物整理）',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'04','生活类','3. 与即将同校的学长学姐交流，了解校园情况',NULL);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','学习类','1. 重视基础课程学习（高数、英语、思政课），确保绩点80+',ARRAY['保研', '留学', '奖学金', '评优', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','学习类','2. 了解英语四级考试要求，开始背单词和做真题',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','学习类','3. 认真对待每门课程的作业和小测验，及时复习',ARRAY['绩点', '保研', '奖学金', '入党']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','实践类','1. 积极参与军训，争取优秀学员称号',ARRAY['保研', '考公', '就业', '评优']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','实践类','2. 竞选班干部或加入1-2个感兴趣的社团/学生会',ARRAY['综测', '保研', '考公', '就业', '评优']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','实践类','3. 参加至少1次校级/院级学术讲座或活动',ARRAY['综测', '保研', '考公', '就业', '评优']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','发展类','1. 提交入团/入党申请书（如有意愿）',ARRAY['党团', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','发展类','2. 与专业导师建立联系，了解专业发展方向',ARRAY['科研', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'11','发展类','3. 研究学校保研政策和转专业要求（如有需要）',ARRAY['转专业', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','学习类','1. 集中备考英语四级，每天2-3小时真题训练',ARRAY['保研', '考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','学习类','2. 复习大一上学期核心课程，为考研学习打基础',ARRAY['科研', '考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','学习类','3. 学习计算机二级考试内容',ARRAY['保研', '考研', '央国企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','实践类','1. 参加共青团“返家乡”社会实践活动',ARRAY['综测', '保研', '央国企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','实践类','2. 参加志愿服务',ARRAY['综测', '保研', '评优', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','实践类','3. 参加线上实习',ARRAY['央国企', '大厂', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','提升类','1. 学习一门实用软件（如PS基础、思维导图工具）',ARRAY['科研', '央国企', '大厂', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','提升类','2. 阅读2-3本书籍',ARRAY['科研', '央国企', '大厂', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'12','提升类','3. 制定大一下学期详细学习和实践计划',ARRAY['保研', '考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','学习类','1. 重点准备英语四级考试，确保顺利通过',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','学习类','2. 保持高绩点（85+优先）',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','学习类','3. 了解辅修专业政策，确定是否需要辅修',ARRAY['考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','学习类','4. 认真对待期中、期末考试和暑假小学期学习',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','实践类','1. 参与金工实习（如有），认真完成实习报告',ARRAY['奖学金', '评优', '综测']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','实践类','2. 在社团/学生会中承担具体工作任务，提升组织能力',ARRAY['综测', '保研', '考公', '就业', '评优']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','实践类','3. 参加1次学科竞赛（如数学建模、英语竞赛）',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','实践类','4. 参与至少1次志愿服务活动（累计时长）',ARRAY['综测', '保研', '评优', '央企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','发展类','1. 申请转专业（如有需要，按学校要求准备材料）',ARRAY['转专业', '保研', '考公', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','发展类','2. 关注奖学金申请通知，准备相关材料',ARRAY['奖学金', '评优', '保研', '央企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','发展类','3. 了解大类专业分方向情况，确定自己的专业方向',ARRAY['保研', '考研', '央企', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','发展类','4. 参加职业规划讲座，明确初步发展方向',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','技能类','1. 完成计算机二级考试（如有报名）',ARRAY['考研', '央企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','技能类','2. 学习学术论文写作基础，尝试写1篇课程小论文',ARRAY['科研', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'13','技能类','3. 提升演讲表达能力，参加1次班级/社团演讲活动',ARRAY['奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','学习类','1. 通过四级的同学开始准备英语六级，未通过的继续备考',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','学习类','2. 预习大二核心专业课程，阅读相关专业文献',ARRAY['科研', '保研', '考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','学习类','3. 参加学校或机构组织的学习营',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','实践类','1. 寻找1份与专业相关的短期实习（2-4周）',ARRAY['央国企', '大厂', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','实践类','2. 参加三下乡社会实践活动或志愿服务',ARRAY['综测', '保研', '央企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','实践类','3. 尝试独立完成1个小型实践项目（如社会调研）',ARRAY['综测', '科研', '保研', '央企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','技能类','1. 完成驾驶证考试（如有剩余科目）',ARRAY['央国企', '大厂', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','技能类','2. 深入学习专业相关软件（根据专业选择）',ARRAY['综测', '科研', '保研', '央企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'14','技能类','3. 提升办公软件高级应用能力（如Excel函数、PPT设计）',ARRAY['科研', '保研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','学习类','1. 重点学习专业核心课程，保持高绩点',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','学习类','2. 准备英语六级考试，争取高分通过',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','学习类','3. 开始了解考研专业方向或就业领域要求',ARRAY['考研', '央企', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','学习类','4. 准备普通话证书考试（尤其是师范类专业）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','实践类','1. 参与科研项目（如老师的课题、大学生创新项目）',ARRAY['科研', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','实践类','2. 参加高水平学科竞赛（如挑战杯、互联网+）',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','实践类','3. 在社团/学生会中担任负责人职务（如有能力）',ARRAY['综测', '保研', '考公', '就业', '评优']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','实践类','4. 积累志愿者服务时长（满足毕业要求）',ARRAY['综测', '保研', '评优', '央企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','发展类','1. 确定未来发展方向（考研、就业、留学、保研）',ARRAY['考研', '就业', '留学', '保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','发展类','2. 开始辅修专业学习（如有选择）',ARRAY['考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','发展类','3. 关注入党积极分子培养和发展',ARRAY['党团', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','发展类','4. 了解初级会计职称等专业相关证书要求',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','技能类','1. 准备并参加计算机二级考试（未通过的同学）',ARRAY['考研', '央企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','技能类','2. 学习专业相关的编程语言或工具（根据专业）',ARRAY['考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'21','技能类','3. 提升文献检索和整理能力，学会使用知网等数据库',ARRAY['科研', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','学习类','1. 备考英语六级（未通过的同学）或刷分（已通过的同学）',ARRAY['保研', '考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','学习类','2. 准备专业相关证书考试（如初级会计、教师资格证笔试）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','学习类','3. 阅读1-2本书籍，撰写读书笔记',ARRAY['保研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','实践类','1. 寻找1份高质量的专业相关实习（4周以上）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','实践类','2. 参加大学生竞赛的寒假集训',ARRAY['保研', '考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','实践类','3. 参加志愿服务或公益活动',ARRAY['保研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','规划类','1. 了解目标院校考研情况或目标企业招聘要求',ARRAY['考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','规划类','2. 评估自己的优势和不足，确定需要提升的方向',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','提升类','1. 学习一门实用软件（如视频剪辑、设计工具）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','提升类','2. 提升人际交往能力，参加社交活动',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'22','提升类','3. 总结上一年度学习和实践经验，调整规划',ARRAY['保研', '考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','学习类','1. 继续保持高绩点，重视专业核心课程',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','学习类','2. 通过英语六级考试（优先）',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','学习类','3. 准备雅思/托福（计划留学的同学）',ARRAY['保研', '留学', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','学习类','4. 备考专业相关证书（如初级会计、教师资格证面试）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','实践类','1. 深入参与科研项目，争取发表论文或申请专利',ARRAY['考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','实践类','2. 参加国际交换生项目选拔（如有机会）',ARRAY['留学', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','实践类','3. 寻找专业导师，争取进入课题组学习',ARRAY['科研', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','实践类','4. 参加行业企业参观或实习（短期）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','发展类','1. 确定专业细分方向，了解该方向的就业/升学前景',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','发展类','2. 申请入党（如符合条件）',ARRAY['党团', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','发展类','3. 关注奖学金申请通知，准备相关材料',ARRAY['奖学金', '评优', '保研', '央企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','发展类','4. 参加职业规划辅导，明确发展路径',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','技能类','1. 学习专业高级软件或工具，提升专业技能',ARRAY['考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','技能类','2. 提升团队协作和项目管理能力',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'23','技能类','3. 学习翻译技巧（如需要），准备翻译证书考试',ARRAY['保研', '考研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','学习类','1. 考研同学开始系统复习数学和英语',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','学习类','2. 留学同学集中备考雅思/托福，目标分数达标',ARRAY['留学']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','学习类','3. 学习专业前沿知识，阅读行业报告',ARRAY['保研', '留学', '奖学金', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','学习类','4. 准备下学期专业课程学习',ARRAY['保研', '考研', '奖学金']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','实践类','1. 争取1份央国企或知名企业的实习（6-8周）',ARRAY['央国企', '大厂', '外企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','实践类','2. 主持或核心参与1个大学生创新项目',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','实践类','3. 参加三下乡或返家乡社会实践活动（如有需要）',ARRAY['综测', '保研', '央企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'24','实践类','4. 完成科研项目的关键阶段工作',ARRAY['科研', '保研', '考公', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','学习类','1. 保研同学保持高绩点，重视专业核心课程',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','学习类','2. 了解考研相关内容，择校择专业',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','学习类','3. 备考教师资格证（师范类专业）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','学习类','4. 学习考公相关知识（计划考公的同学）',ARRAY['考公']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','实践类','1. 争取高质量实习（与目标就业方向一致）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','实践类','2. 发表学术论文（保研/考研同学优先）',ARRAY['科研', '保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','实践类','3. 参与导师的科研项目，积累科研经历',ARRAY['科研', '保研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','发展类','1. 保研同学了解目标院校和导师信息，准备联系',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','发展类','2. 考研同学确定目标院校和专业，购买复习资料',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','发展类','3. 留学同学准备申请材料（推荐信、个人陈述）',ARRAY['留学']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','发展类','4. 就业同学开始关注企业秋招信息（部分企业）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','技能类','1. 学习数据分析工具（如Python、SPSS）',ARRAY['保研', '考研', '科研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','技能类','2. 提升专业文档写作能力',ARRAY['保研', '考研', '科研', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','技能类','3. 准备导游证等特色证书（如有需要）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'31','技能类','4. 提升职场沟通和商务礼仪能力',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','学习类','1. 考研同学进行寒假学习',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','学习类','2. 保研同学准备夏令营申请材料',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','学习类','3. 考公同学开始系统复习行测和申论',ARRAY['考公']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','实践类','1. 参加企业实习',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','实践类','2. 完成科研项目收尾工作，准备论文发表',ARRAY['保研', '科研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','实践类','3. 参加行业培训或短期课程',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','实践类','4. 如果没有参加过社会实践，这个寒假要参加“返家乡”社会实践',ARRAY['保研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','规划类','1. 确定最终发展方向，不犹豫不摇摆',ARRAY['考研', '留学', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','规划类','2. 收集目标院校/企业的详细信息',ARRAY['考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','规划类','3. 准备新学期的各项申请材料',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','提升类','1. 优化个人简历，针对目标方向调整',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','提升类','2. 提升抗压能力，为紧张的下学期做准备',ARRAY['保研', '考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'32','提升类','3. 建立行业人脉，与目标企业员工交流',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','学习类','1. 考研同学进入正式学习',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','学习类','2. 保研同学参加目标院校夏令营',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','学习类','3. 考公同学强化行测和申论训练',ARRAY['考公']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','学习类','4. 完成大学剩余课程学习，确保顺利毕业',ARRAY['保研', '留学', '奖学金', '评优', '央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','实践类','1. 就业同学寻找实习机会，为秋招做准备',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','实践类','2. 保研同学在夏令营中展示自己，争取预录取',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','实践类','3. 参加行业实践项目，积累项目经验',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','发展类','1. 保研同学准备预推免材料，联系导师',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','发展类','2. 考研同学评估自己是否需要报名参加考研辅导班',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','发展类','3. 留学同学完成所有申请材料提交',ARRAY['留学']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','发展类','4. 就业同学关注企业暑期实习招聘',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','技能类','1. 提升笔试能力，准备企业笔试',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','技能类','2. 学习商务英语（如需要）',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'33','技能类','3. 提升团队领导能力',ARRAY['央企', '外企', '大厂']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','学习类','1. 考研同学全力以赴复习，每天8-10小时学习时间',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','学习类','2. 保研同学参加预推免面试',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','学习类','3. 考公同学进行封闭训练，提高答题速度',ARRAY['考公']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','学习类','4. 学习央国企笔试相关知识（就业同学）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','实践类','1. 就业同学参加企业暑期实习，争取留用机会',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','实践类','2. 保研同学在目标院校做短期科研（如有机会）',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','实践类','3. 参与社会实践或志愿服务',ARRAY['综测', '保研', '央企']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','发展类','1. 就业同学开始准备秋招，制作针对性简历',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','发展类','2. 考研同学确定专业课',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','发展类','3. 留学同学跟进申请进度，准备面试',ARRAY['留学']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','发展类','4. 考公同学了解招考职位信息，确定报考方向',ARRAY['考公']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','准备类','1. 收集秋招企业信息',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','准备类','2. 学习简历制作和面试技巧，参加求职培训',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','准备类','3. 调整心态，保持积极乐观',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'34','准备类','4. 准备求职所需的各项材料（成绩单、证书等）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','学习类','1. 考研同学最后冲刺复习，调整作息适应考试时间',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','学习类','2. 考公同学本学期国考报名和考试',ARRAY['考公']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','学习类','3. 完成剩余课程学习和考试',ARRAY['奖学金', '评优']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','学习类','4. 学习企业笔试相关知识（就业同学）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','求职类','1. 积极参加企业秋招，投递简历（20-30家）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','求职类','2. 参加校园招聘会和企业宣讲会',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','求职类','3. 认真准备每一次面试，及时总结经验',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','求职类','4. 争取拿到2-3个offer，选择最优',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','发展类','1. 保研同学完成推免手续，确定录取院校',ARRAY['保研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','发展类','2. 考研同学参加研究生考试',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'41','发展类','3. 留学同学确认录取结果，准备签证',ARRAY['留学']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','学习类','1. 考研同学准备复试，学习专业知识',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','学习类','2. 考公同学准备面试，进行模拟训练/准备省考',ARRAY['考公']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','学习类','3. 未拿到满意offer的同学继续学习求职技能',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','实践类','1. 参加企业实习',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','实践类','2. 进行毕业论文实地调研或实验',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','实践类','3. 参加行业活动，拓展就业渠道',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','就业类','1. 跟进秋招offer情况，确定最终选择',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','就业类','2. 关注春招信息，开始准备投递简历（未就业同学）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','就业类','3. 与用人单位沟通入职事宜',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','毕业类','1. 修改完善毕业论文',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'42','毕业类','2. 准备毕业论文答辩PPT',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','学习类','1. 考研同学参加复试，争取录取',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','学习类','2. 考研失利同学准备调剂或开始求职',ARRAY['考研', '就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','学习类','3. 完成毕业论文最后修改',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','学习类','4. 学习职场适应知识，为入职做准备',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','就业类','1. 积极参与春招，争取拿到满意offer',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','就业类','2. 与用人单位签订就业协议',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','就业类','3. 了解入职前准备事项（如体检、培训）',ARRAY['就业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','就业类','4. 参加学校就业指导和离校教育',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','毕业类','1. 参加毕业论文答辩',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','毕业类','2. 办理离校手续（退宿、转档案、户口迁移）',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','毕业类','3. 参加毕业典礼和毕业照拍摄',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','毕业类','4. 整理大学四年资料和物品',ARRAY['毕业']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','发展类','1. 了解研究生阶段学习计划（升学同学）',ARRAY['考研']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','发展类','2. 准备出国所需材料（留学同学）',ARRAY['留学']);
insert into study_checklist(id,semester,category,title,tags) values(uuid_generate_v4(),'43','发展类','3. 关注基层项目（如三支一扶、西部计划）报名信息',ARRAY['体制内就业']);
